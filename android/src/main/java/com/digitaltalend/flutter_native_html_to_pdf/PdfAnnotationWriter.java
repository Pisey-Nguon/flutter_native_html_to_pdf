package com.digitaltalend.flutter_native_html_to_pdf;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.TreeMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

final class PdfAnnotationWriter {

    private static final Pattern OBJECT_HEADER_PATTERN = Pattern.compile("(?m)^(\\d+)\\s+(\\d+)\\s+obj\\s*$");
    private static final Pattern REF_PATTERN = Pattern.compile("(\\d+)\\s+(\\d+)\\s+R");
    private static final Pattern TRAILER_SIZE_PATTERN = Pattern.compile("/Size\\s+(\\d+)");
    private static final Pattern TRAILER_ROOT_PATTERN = Pattern.compile("/Root\\s+(\\d+)\\s+(\\d+)\\s+R");
    private static final Pattern TRAILER_INFO_PATTERN = Pattern.compile("/Info\\s+(\\d+)\\s+(\\d+)\\s+R");
    private static final Pattern TYPE_PAGE_PATTERN = Pattern.compile("/Type\\s*/Page(?!s)\\b");
    private static final Pattern TYPE_PAGES_PATTERN = Pattern.compile("/Type\\s*/Pages\\b");

    private PdfAnnotationWriter() {
    }

    static void addUriLinks(
            File pdfFile,
            List<PdfLinkMapper.HtmlLinkRect> linkRects,
            double contentWidthCss,
            float pageWidthPoints,
            float pageHeightPoints) throws IOException {

        if (linkRects == null || linkRects.isEmpty()) {
            return;
        }

        byte[] originalBytes = Files.readAllBytes(pdfFile.toPath());
        ParsedPdf parsedPdf = ParsedPdf.parse(originalBytes);
        if (parsedPdf.pageRefs.isEmpty()) {
            return;
        }

        List<PdfLinkMapper.PdfPageLink> pageLinks = PdfLinkMapper.mapToPdfPages(
                linkRects,
                contentWidthCss,
                pageWidthPoints,
                pageHeightPoints,
                parsedPdf.pageRefs.size()
        );
        if (pageLinks.isEmpty()) {
            return;
        }

        Map<Integer, List<PdfLinkMapper.PdfPageLink>> linksByPage = new HashMap<>();
        for (PdfLinkMapper.PdfPageLink pageLink : pageLinks) {
            linksByPage.computeIfAbsent(pageLink.pageIndex, ignored -> new ArrayList<>()).add(pageLink);
        }

        ByteArrayOutputStream appendStream = new ByteArrayOutputStream();
        Map<Integer, XrefEntry> xrefEntries = new TreeMap<>();
        int nextObjectNumber = parsedPdf.size;

        for (int pageIndex = 0; pageIndex < parsedPdf.pageRefs.size(); pageIndex++) {
            List<PdfLinkMapper.PdfPageLink> pageSpecificLinks = linksByPage.get(pageIndex);
            if (pageSpecificLinks == null || pageSpecificLinks.isEmpty()) {
                continue;
            }

            PdfRef pageRef = parsedPdf.pageRefs.get(pageIndex);
            ParsedObject pageObject = parsedPdf.requireObject(pageRef);

            List<PdfRef> newAnnotationRefs = new ArrayList<>();
            for (PdfLinkMapper.PdfPageLink pageLink : pageSpecificLinks) {
                PdfRef annotationRef = new PdfRef(nextObjectNumber++, 0);
                newAnnotationRefs.add(annotationRef);
                long offset = originalBytes.length + appendStream.size();
                writeString(appendStream, buildAnnotationObject(annotationRef, pageLink, pageHeightPoints));
                xrefEntries.put(annotationRef.objectNumber, new XrefEntry(annotationRef.objectNumber, annotationRef.generation, offset));
            }

            String updatedPageObject = buildUpdatedPageObject(pageObject, parsedPdf, newAnnotationRefs);
            long offset = originalBytes.length + appendStream.size();
            writeString(appendStream, updatedPageObject);
            xrefEntries.put(pageRef.objectNumber, new XrefEntry(pageRef.objectNumber, pageRef.generation, offset));
        }

        if (xrefEntries.isEmpty()) {
            return;
        }

        ByteArrayOutputStream outputStream = new ByteArrayOutputStream(originalBytes.length + appendStream.size() + 1024);
        outputStream.write(originalBytes);
        if (originalBytes.length == 0 || originalBytes[originalBytes.length - 1] != '\n') {
            outputStream.write('\n');
        }
        outputStream.write(appendStream.toByteArray());

        long xrefOffset = outputStream.size();
        writeString(outputStream, buildIncrementalXref(parsedPdf, xrefEntries, nextObjectNumber, xrefOffset));
        Files.write(pdfFile.toPath(), outputStream.toByteArray());
    }

    private static String buildAnnotationObject(PdfRef annotationRef, PdfLinkMapper.PdfPageLink pageLink, float pageHeightPoints) {
        float lowerLeftY = Math.max(pageHeightPoints - pageLink.topPoints - pageLink.heightPoints, 0f);
        float upperRightY = lowerLeftY + pageLink.heightPoints;
        float upperRightX = pageLink.leftPoints + pageLink.widthPoints;

        return annotationRef.objectNumber + " " + annotationRef.generation + " obj\n"
                + "<<\n"
                + "/Type /Annot\n"
                + "/Subtype /Link\n"
                + "/Rect [" + formatNumber(pageLink.leftPoints) + " "
                + formatNumber(lowerLeftY) + " "
                + formatNumber(upperRightX) + " "
                + formatNumber(upperRightY) + "]\n"
                + "/Border [0 0 0]\n"
                + "/A << /S /URI /URI (" + escapePdfString(pageLink.href) + ") >>\n"
                + ">>\n"
                + "endobj\n";
    }

    private static String buildUpdatedPageObject(ParsedObject pageObject, ParsedPdf parsedPdf, List<PdfRef> newAnnotationRefs) throws IOException {
        String body = pageObject.body;
        int dictStart = body.indexOf("<<");
        if (dictStart < 0) {
            throw new IOException("Page object dictionary not found");
        }
        int dictEnd = findMatchingDictionaryEnd(body, dictStart);
        String dictionary = body.substring(dictStart, dictEnd + 1);

        String existingAnnots = extractExistingAnnotations(dictionary, parsedPdf);
        StringBuilder annotsBuilder = new StringBuilder();
        if (existingAnnots != null && !existingAnnots.trim().isEmpty()) {
            annotsBuilder.append(existingAnnots.trim());
        }
        for (PdfRef annotationRef : newAnnotationRefs) {
            if (annotsBuilder.length() > 0) {
                annotsBuilder.append(' ');
            }
            annotsBuilder.append(annotationRef.objectNumber).append(' ').append(annotationRef.generation).append(" R");
        }

        String replacement = "/Annots [" + annotsBuilder + "]";
        int annotsIndex = dictionary.indexOf("/Annots");
        String updatedDictionary;
        if (annotsIndex >= 0) {
            int annotsValueStart = annotsIndex + "/Annots".length();
            while (annotsValueStart < dictionary.length() && Character.isWhitespace(dictionary.charAt(annotsValueStart))) {
                annotsValueStart++;
            }
            int annotsValueEnd = findAnnotationValueEnd(dictionary, annotsValueStart);
            updatedDictionary = dictionary.substring(0, annotsIndex)
                    + replacement
                    + dictionary.substring(annotsValueEnd);
        } else {
            updatedDictionary = dictionary.substring(0, dictionary.length() - 2)
                    + "\n"
                    + replacement
                    + "\n>>";
        }

        String updatedBody = body.substring(0, dictStart) + updatedDictionary + body.substring(dictEnd + 1);
        return pageObject.ref.objectNumber + " " + pageObject.ref.generation + " obj\n"
                + updatedBody.trim() + "\n"
                + "endobj\n";
    }

    private static String extractExistingAnnotations(String dictionary, ParsedPdf parsedPdf) throws IOException {
        int annotsIndex = dictionary.indexOf("/Annots");
        if (annotsIndex < 0) {
            return null;
        }
        int valueStart = annotsIndex + "/Annots".length();
        while (valueStart < dictionary.length() && Character.isWhitespace(dictionary.charAt(valueStart))) {
            valueStart++;
        }
        if (valueStart >= dictionary.length()) {
            return null;
        }

        char firstChar = dictionary.charAt(valueStart);
        if (firstChar == '[') {
            int arrayEnd = findMatchingArrayEnd(dictionary, valueStart);
            return dictionary.substring(valueStart + 1, arrayEnd);
        }

        Matcher matcher = REF_PATTERN.matcher(dictionary.substring(valueStart));
        if (!matcher.lookingAt()) {
            return null;
        }
        PdfRef annotsRef = new PdfRef(Integer.parseInt(matcher.group(1)), Integer.parseInt(matcher.group(2)));
        ParsedObject annotationsObject = parsedPdf.objects.get(annotsRef.objectNumber);
        if (annotationsObject == null) {
            return null;
        }
        String body = annotationsObject.body.trim();
        if (!body.startsWith("[")) {
            return null;
        }
        int arrayEnd = findMatchingArrayEnd(body, 0);
        return body.substring(1, arrayEnd);
    }

    private static int findAnnotationValueEnd(String dictionary, int valueStart) throws IOException {
        if (valueStart >= dictionary.length()) {
            return valueStart;
        }
        char valueType = dictionary.charAt(valueStart);
        if (valueType == '[') {
            return findMatchingArrayEnd(dictionary, valueStart) + 1;
        }
        Matcher matcher = REF_PATTERN.matcher(dictionary.substring(valueStart));
        if (matcher.lookingAt()) {
            return valueStart + matcher.end();
        }
        throw new IOException("Unsupported /Annots value in page dictionary");
    }

    private static String buildIncrementalXref(
            ParsedPdf parsedPdf,
            Map<Integer, XrefEntry> xrefEntries,
            int size,
            long xrefOffset) {

        StringBuilder builder = new StringBuilder();
        builder.append("xref\n");

        List<XrefEntry> entries = new ArrayList<>(xrefEntries.values());
        entries.sort(Comparator.comparingInt(entry -> entry.objectNumber));

        int index = 0;
        while (index < entries.size()) {
            int startObject = entries.get(index).objectNumber;
            int endIndex = index;
            while (endIndex + 1 < entries.size()
                    && entries.get(endIndex + 1).objectNumber == entries.get(endIndex).objectNumber + 1) {
                endIndex++;
            }

            builder.append(startObject)
                    .append(' ')
                    .append(endIndex - index + 1)
                    .append('\n');
            for (int i = index; i <= endIndex; i++) {
                XrefEntry entry = entries.get(i);
                builder.append(String.format(Locale.US, "%010d %05d n \n", entry.offset, entry.generation));
            }

            index = endIndex + 1;
        }

        builder.append("trailer\n<<\n")
                .append("/Size ").append(size).append('\n')
                .append("/Root ").append(parsedPdf.rootRef.objectNumber).append(' ').append(parsedPdf.rootRef.generation).append(" R\n")
                .append("/Prev ").append(parsedPdf.startXref).append('\n');
        if (parsedPdf.infoRef != null) {
            builder.append("/Info ").append(parsedPdf.infoRef.objectNumber).append(' ').append(parsedPdf.infoRef.generation).append(" R\n");
        }
        if (parsedPdf.idEntry != null && !parsedPdf.idEntry.isEmpty()) {
            builder.append("/ID ").append(parsedPdf.idEntry).append('\n');
        }
        builder.append(">>\n")
                .append("startxref\n")
                .append(xrefOffset)
                .append("\n%%EOF\n");
        return builder.toString();
    }

    private static int findMatchingDictionaryEnd(String source, int dictStart) throws IOException {
        int depth = 0;
        for (int index = dictStart; index < source.length() - 1; index++) {
            char current = source.charAt(index);
            char next = source.charAt(index + 1);
            if (current == '<' && next == '<') {
                depth++;
                index++;
                continue;
            }
            if (current == '>' && next == '>') {
                depth--;
                index++;
                if (depth == 0) {
                    return index;
                }
            }
        }
        throw new IOException("Unterminated PDF dictionary");
    }

    private static int findMatchingArrayEnd(String source, int arrayStart) throws IOException {
        int depth = 0;
        boolean inString = false;
        boolean escaped = false;
        for (int index = arrayStart; index < source.length(); index++) {
            char current = source.charAt(index);
            if (inString) {
                if (escaped) {
                    escaped = false;
                } else if (current == '\\') {
                    escaped = true;
                } else if (current == ')') {
                    inString = false;
                }
                continue;
            }
            if (current == '(') {
                inString = true;
                continue;
            }
            if (current == '[') {
                depth++;
            } else if (current == ']') {
                depth--;
                if (depth == 0) {
                    return index;
                }
            }
        }
        throw new IOException("Unterminated PDF array");
    }

    private static String extractArray(String source, String key) throws IOException {
        int keyIndex = source.indexOf(key);
        if (keyIndex < 0) {
            return null;
        }
        int arrayStart = source.indexOf('[', keyIndex + key.length());
        if (arrayStart < 0) {
            return null;
        }
        int arrayEnd = findMatchingArrayEnd(source, arrayStart);
        return source.substring(arrayStart + 1, arrayEnd);
    }

    private static List<PdfRef> parseRefs(String text) {
        if (text == null || text.isEmpty()) {
            return Collections.emptyList();
        }
        List<PdfRef> refs = new ArrayList<>();
        Matcher matcher = REF_PATTERN.matcher(text);
        while (matcher.find()) {
            refs.add(new PdfRef(Integer.parseInt(matcher.group(1)), Integer.parseInt(matcher.group(2))));
        }
        return refs;
    }

    private static String formatNumber(float value) {
        String formatted = String.format(Locale.US, "%.4f", value);
        int end = formatted.length();
        while (end > 0 && formatted.charAt(end - 1) == '0') {
            end--;
        }
        if (end > 0 && formatted.charAt(end - 1) == '.') {
            end--;
        }
        return formatted.substring(0, Math.max(end, 1));
    }

    private static String escapePdfString(String value) {
        StringBuilder builder = new StringBuilder(value.length() + 8);
        for (int i = 0; i < value.length(); i++) {
            char current = value.charAt(i);
            if (current == '\\' || current == '(' || current == ')') {
                builder.append('\\');
            }
            if (current == '\r') {
                builder.append("\\r");
            } else if (current == '\n') {
                builder.append("\\n");
            } else {
                builder.append(current);
            }
        }
        return builder.toString();
    }

    private static void writeString(ByteArrayOutputStream stream, String value) {
        byte[] bytes = value.getBytes(StandardCharsets.ISO_8859_1);
        stream.write(bytes, 0, bytes.length);
    }

    private static final class ParsedPdf {
        final Map<Integer, ParsedObject> objects;
        final PdfRef rootRef;
        final PdfRef infoRef;
        final String idEntry;
        final int size;
        final long startXref;
        final List<PdfRef> pageRefs;

        private ParsedPdf(
                Map<Integer, ParsedObject> objects,
                PdfRef rootRef,
                PdfRef infoRef,
                String idEntry,
                int size,
                long startXref,
                List<PdfRef> pageRefs) {
            this.objects = objects;
            this.rootRef = rootRef;
            this.infoRef = infoRef;
            this.idEntry = idEntry;
            this.size = size;
            this.startXref = startXref;
            this.pageRefs = pageRefs;
        }

        static ParsedPdf parse(byte[] bytes) throws IOException {
            String pdf = new String(bytes, StandardCharsets.ISO_8859_1);
            long startXref = parseStartXref(pdf);
            String trailer = parseTrailer(pdf, startXref);
            PdfRef rootRef = parseRequiredRef(TRAILER_ROOT_PATTERN, trailer, "Root");
            PdfRef infoRef = parseOptionalRef(TRAILER_INFO_PATTERN, trailer);
            int size = parseRequiredInt(TRAILER_SIZE_PATTERN, trailer, "Size");
            String idEntry = extractArray(trailer, "/ID");

            Map<Integer, ParsedObject> objects = parseObjects(pdf);
            ParsedObject catalogObject = objects.get(rootRef.objectNumber);
            if (catalogObject == null) {
                throw new IOException("Catalog object not found");
            }
            PdfRef pagesRef = parseRequiredRef(Pattern.compile("/Pages\\s+(\\d+)\\s+(\\d+)\\s+R"), catalogObject.body, "Pages");
            List<PdfRef> pageRefs = collectPageRefs(pagesRef, objects);

            return new ParsedPdf(objects, rootRef, infoRef, idEntry != null ? "[" + idEntry + "]" : null, size, startXref, pageRefs);
        }

        ParsedObject requireObject(PdfRef ref) throws IOException {
            ParsedObject object = objects.get(ref.objectNumber);
            if (object == null) {
                throw new IOException("Object " + ref.objectNumber + " not found");
            }
            return object;
        }

        private static long parseStartXref(String pdf) throws IOException {
            int startXrefIndex = pdf.lastIndexOf("startxref");
            if (startXrefIndex < 0) {
                throw new IOException("PDF startxref not found");
            }
            int cursor = startXrefIndex + "startxref".length();
            while (cursor < pdf.length() && Character.isWhitespace(pdf.charAt(cursor))) {
                cursor++;
            }
            int numberStart = cursor;
            while (cursor < pdf.length() && Character.isDigit(pdf.charAt(cursor))) {
                cursor++;
            }
            if (numberStart == cursor) {
                throw new IOException("PDF startxref value not found");
            }
            return Long.parseLong(pdf.substring(numberStart, cursor));
        }

        private static String parseTrailer(String pdf, long startXref) throws IOException {
            int xrefIndex = (int) startXref;
            if (xrefIndex < 0 || xrefIndex >= pdf.length()) {
                throw new IOException("Invalid startxref offset");
            }
            int trailerIndex = pdf.indexOf("trailer", xrefIndex);
            if (trailerIndex < 0) {
                throw new IOException("PDF trailer not found");
            }
            int dictStart = pdf.indexOf("<<", trailerIndex);
            if (dictStart < 0) {
                throw new IOException("PDF trailer dictionary not found");
            }
            int dictEnd = findMatchingDictionaryEnd(pdf, dictStart);
            return pdf.substring(dictStart, dictEnd + 1);
        }

        private static Map<Integer, ParsedObject> parseObjects(String pdf) throws IOException {
            Map<Integer, ParsedObject> objects = new HashMap<>();
            Matcher matcher = OBJECT_HEADER_PATTERN.matcher(pdf);
            while (matcher.find()) {
                int objectNumber = Integer.parseInt(matcher.group(1));
                int generation = Integer.parseInt(matcher.group(2));
                int bodyStart = matcher.end();
                int endObject = pdf.indexOf("endobj", bodyStart);
                if (endObject < 0) {
                    throw new IOException("Unterminated object " + objectNumber);
                }
                String body = pdf.substring(bodyStart, endObject).trim();
                objects.put(objectNumber, new ParsedObject(new PdfRef(objectNumber, generation), body));
            }
            return objects;
        }

        private static List<PdfRef> collectPageRefs(PdfRef pagesRef, Map<Integer, ParsedObject> objects) throws IOException {
            ParsedObject pagesObject = objects.get(pagesRef.objectNumber);
            if (pagesObject == null) {
                throw new IOException("Pages object not found");
            }
            String body = pagesObject.body;
            if (TYPE_PAGE_PATTERN.matcher(body).find() && !TYPE_PAGES_PATTERN.matcher(body).find()) {
                return Collections.singletonList(pagesRef);
            }

            List<PdfRef> pageRefs = new ArrayList<>();
            for (PdfRef kidRef : parseRefs(extractArray(body, "/Kids"))) {
                pageRefs.addAll(collectPageRefs(kidRef, objects));
            }
            return pageRefs;
        }

        private static PdfRef parseRequiredRef(Pattern pattern, String source, String label) throws IOException {
            PdfRef ref = parseOptionalRef(pattern, source);
            if (ref == null) {
                throw new IOException("PDF trailer field not found: " + label);
            }
            return ref;
        }

        private static PdfRef parseOptionalRef(Pattern pattern, String source) {
            Matcher matcher = pattern.matcher(source);
            if (!matcher.find()) {
                return null;
            }
            return new PdfRef(Integer.parseInt(matcher.group(1)), Integer.parseInt(matcher.group(2)));
        }

        private static int parseRequiredInt(Pattern pattern, String source, String label) throws IOException {
            Matcher matcher = pattern.matcher(source);
            if (!matcher.find()) {
                throw new IOException("PDF trailer field not found: " + label);
            }
            return Integer.parseInt(matcher.group(1));
        }
    }

    private static final class ParsedObject {
        final PdfRef ref;
        final String body;

        ParsedObject(PdfRef ref, String body) {
            this.ref = ref;
            this.body = body;
        }
    }

    private static final class PdfRef {
        final int objectNumber;
        final int generation;

        PdfRef(int objectNumber, int generation) {
            this.objectNumber = objectNumber;
            this.generation = generation;
        }
    }

    private static final class XrefEntry {
        final int objectNumber;
        final int generation;
        final long offset;

        XrefEntry(int objectNumber, int generation, long offset) {
            this.objectNumber = objectNumber;
            this.generation = generation;
            this.offset = offset;
        }
    }
}