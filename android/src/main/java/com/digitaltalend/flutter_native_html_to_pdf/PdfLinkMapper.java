package com.digitaltalend.flutter_native_html_to_pdf;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

final class PdfLinkMapper {

    private static final float CSS_PIXELS_PER_POINT = 96f / 72f;

    private PdfLinkMapper() {
    }

    static double defaultContentWidthCss(float pageWidthPoints) {
        return Math.max(pageWidthPoints * CSS_PIXELS_PER_POINT, 1f);
    }

    static List<PdfPageLink> mapToPdfPages(
            List<HtmlLinkRect> links,
            double contentWidthCss,
            float pageWidthPoints,
            float pageHeightPoints,
            int pageCount) {

        if (links == null || links.isEmpty() || pageCount <= 0 || pageWidthPoints <= 0f || pageHeightPoints <= 0f) {
            return Collections.emptyList();
        }

        double effectiveContentWidthCss = contentWidthCss > 0d
                ? contentWidthCss
                : defaultContentWidthCss(pageWidthPoints);
        float scale = (float) (pageWidthPoints / effectiveContentWidthCss);
        if (!Float.isFinite(scale) || scale <= 0f) {
            return Collections.emptyList();
        }

        float pageHeightCss = pageHeightPoints / scale;
        if (!Float.isFinite(pageHeightCss) || pageHeightCss <= 0f) {
            return Collections.emptyList();
        }

        List<PdfPageLink> pageLinks = new ArrayList<>();
        for (HtmlLinkRect link : links) {
            if (link == null || link.href == null || link.href.isEmpty()) {
                continue;
            }
            if (link.widthCss <= 0d || link.heightCss <= 0d) {
                continue;
            }

            double currentYCss = link.yCss;
            double remainingHeightCss = link.heightCss;
            if (currentYCss < 0d) {
                remainingHeightCss += currentYCss;
                currentYCss = 0d;
            }
            if (remainingHeightCss <= 0d) {
                continue;
            }

            while (remainingHeightCss > 0d) {
                int pageIndex = (int) Math.floor(currentYCss / pageHeightCss);
                if (pageIndex < 0) {
                    pageIndex = 0;
                }
                if (pageIndex >= pageCount) {
                    break;
                }

                double yOnPageCss = currentYCss - (pageIndex * pageHeightCss);
                double availableHeightCss = pageHeightCss - yOnPageCss;
                if (availableHeightCss <= 0d) {
                    currentYCss = (pageIndex + 1d) * pageHeightCss;
                    continue;
                }

                double segmentHeightCss = Math.min(remainingHeightCss, availableHeightCss);
                if (segmentHeightCss <= 0d) {
                    break;
                }

                pageLinks.add(new PdfPageLink(
                        link.href,
                        pageIndex,
                        (float) (link.xCss * scale),
                        (float) (yOnPageCss * scale),
                        (float) (link.widthCss * scale),
                        (float) (segmentHeightCss * scale)
                ));

                currentYCss += segmentHeightCss;
                remainingHeightCss -= segmentHeightCss;
            }
        }

        return pageLinks;
    }

    static final class HtmlLinkRect {
        final String href;
        final double xCss;
        final double yCss;
        final double widthCss;
        final double heightCss;

        HtmlLinkRect(String href, double xCss, double yCss, double widthCss, double heightCss) {
            this.href = href;
            this.xCss = xCss;
            this.yCss = yCss;
            this.widthCss = widthCss;
            this.heightCss = heightCss;
        }
    }

    static final class PdfPageLink {
        final String href;
        final int pageIndex;
        final float leftPoints;
        final float topPoints;
        final float widthPoints;
        final float heightPoints;

        PdfPageLink(
                String href,
                int pageIndex,
                float leftPoints,
                float topPoints,
                float widthPoints,
                float heightPoints) {
            this.href = href;
            this.pageIndex = pageIndex;
            this.leftPoints = leftPoints;
            this.topPoints = topPoints;
            this.widthPoints = widthPoints;
            this.heightPoints = heightPoints;
        }
    }
}