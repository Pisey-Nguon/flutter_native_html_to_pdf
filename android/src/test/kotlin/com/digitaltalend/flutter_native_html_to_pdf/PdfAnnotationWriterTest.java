package com.digitaltalend.flutter_native_html_to_pdf;

import static org.junit.Assert.assertTrue;

import org.junit.Test;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.Collections;
import java.util.Locale;

public class PdfAnnotationWriterTest {

    @Test
    public void addsUriAnnotationWithIncrementalUpdate() throws Exception {
        File tempFile = File.createTempFile("pdf_annotation_writer", ".pdf");
        try {
            Files.write(tempFile.toPath(), createSinglePagePdf().getBytes(StandardCharsets.ISO_8859_1));

            PdfAnnotationWriter.addUriLinks(
                    tempFile,
                    Collections.singletonList(
                            new PdfLinkMapper.HtmlLinkRect("https://example.com", 96d, 144d, 192d, 48d)
                    ),
                    793.6d,
                    595.2f,
                    841.8f
            );

            String updatedPdf = Files.readString(tempFile.toPath(), StandardCharsets.ISO_8859_1);
            assertTrue(updatedPdf.contains("/Subtype /Link"));
            assertTrue(updatedPdf.contains("/URI (https://example.com)"));
            assertTrue(updatedPdf.contains("/Annots [4 0 R]"));
            assertTrue(updatedPdf.contains("/Prev "));
        } finally {
            //noinspection ResultOfMethodCallIgnored
            tempFile.delete();
        }
    }

    private static String createSinglePagePdf() throws Exception {
        String[] objects = new String[]{
                "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n",
                "2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n",
                "3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595.2 841.8] >>\nendobj\n"
        };

        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        writeAscii(stream, "%PDF-1.4\n");
        int[] offsets = new int[objects.length + 1];
        for (int i = 0; i < objects.length; i++) {
            offsets[i + 1] = stream.size();
            writeAscii(stream, objects[i]);
        }

        int xrefOffset = stream.size();
        writeAscii(stream, "xref\n");
        writeAscii(stream, "0 4\n");
        writeAscii(stream, "0000000000 65535 f \n");
        for (int i = 1; i < offsets.length; i++) {
            writeAscii(stream, String.format(Locale.US, "%010d 00000 n \n", offsets[i]));
        }
        writeAscii(stream, "trailer\n");
        writeAscii(stream, "<< /Size 4 /Root 1 0 R >>\n");
        writeAscii(stream, "startxref\n");
        writeAscii(stream, Integer.toString(xrefOffset));
        writeAscii(stream, "\n%%EOF\n");
        return stream.toString(StandardCharsets.ISO_8859_1.name());
    }

    private static void writeAscii(ByteArrayOutputStream stream, String value) {
        byte[] bytes = value.getBytes(StandardCharsets.ISO_8859_1);
        stream.write(bytes, 0, bytes.length);
    }
}