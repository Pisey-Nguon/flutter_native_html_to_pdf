package com.digitaltalend.flutter_native_html_to_pdf;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

import java.util.Collections;
import java.util.List;

public class PdfLinkMapperTest {

    @Test
    public void mapsSinglePageLinkUsingContentWidthScale() {
        List<PdfLinkMapper.PdfPageLink> links = PdfLinkMapper.mapToPdfPages(
                Collections.singletonList(
                        new PdfLinkMapper.HtmlLinkRect(
                                "https://example.com",
                                96d,
                                144d,
                                192d,
                                48d
                        )
                ),
                793.6d,
                595.2f,
                841.8f,
                1
        );

        assertEquals(1, links.size());

        PdfLinkMapper.PdfPageLink link = links.get(0);
        assertEquals(0, link.pageIndex);
        assertEquals(72f, link.leftPoints, 0.01f);
        assertEquals(108f, link.topPoints, 0.01f);
        assertEquals(144f, link.widthPoints, 0.01f);
        assertEquals(36f, link.heightPoints, 0.01f);
    }

    @Test
    public void splitsLinkAcrossPageBoundary() {
        List<PdfLinkMapper.PdfPageLink> links = PdfLinkMapper.mapToPdfPages(
                Collections.singletonList(
                        new PdfLinkMapper.HtmlLinkRect(
                                "https://example.com",
                                32d,
                                1100d,
                                240d,
                                80d
                        )
                ),
                793.6d,
                595.2f,
                841.8f,
                2
        );

        assertEquals(2, links.size());

        PdfLinkMapper.PdfPageLink first = links.get(0);
        PdfLinkMapper.PdfPageLink second = links.get(1);

        assertEquals(0, first.pageIndex);
        assertEquals(24f, first.leftPoints, 0.01f);
        assertEquals(825f, first.topPoints, 0.01f);
        assertEquals(180f, first.widthPoints, 0.01f);
        assertEquals(16.8f, first.heightPoints, 0.01f);

        assertEquals(1, second.pageIndex);
        assertEquals(24f, second.leftPoints, 0.01f);
        assertEquals(0f, second.topPoints, 0.01f);
        assertEquals(180f, second.widthPoints, 0.01f);
        assertEquals(43.2f, second.heightPoints, 0.01f);
    }

    @Test
    public void fallsBackToDefaultCssWidthWhenContentWidthMissing() {
        List<PdfLinkMapper.PdfPageLink> links = PdfLinkMapper.mapToPdfPages(
                Collections.singletonList(
                        new PdfLinkMapper.HtmlLinkRect(
                                "https://example.com",
                                96d,
                                96d,
                                96d,
                                96d
                        )
                ),
                0d,
                595.2f,
                841.8f,
                1
        );

        assertTrue(!links.isEmpty());
        assertEquals(72f, links.get(0).leftPoints, 0.01f);
        assertEquals(72f, links.get(0).topPoints, 0.01f);
    }
}