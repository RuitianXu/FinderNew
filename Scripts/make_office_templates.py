#!/usr/bin/env python3
"""Generate minimal, valid blank OOXML templates (docx/xlsx/pptx).

All XML is authored here from the ECMA-376 spec — no third-party resources.
Output: Resources/OfficeTemplates/blank.docx|.xlsx|.pptx
Verify: unzip -t, then open in Office/LibreOffice/Pages.
"""
import zipfile, pathlib, sys

OUT = pathlib.Path(__file__).resolve().parent.parent / "Resources" / "OfficeTemplates"
OUT.mkdir(parents=True, exist_ok=True)

XMLDECL = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'

def write_zip(path, files):
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        for name, content in files.items():
            z.writestr(name, content)
    print(f"wrote {path} ({path.stat().st_size} bytes)")

# ---------------------------------------------------------------- DOCX
CT_TYPES = XMLDECL + '''<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>'''

RELS_ROOT = XMLDECL + '''<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>'''

RELS_WORD = XMLDECL + '''<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>'''

DOC_XML = XMLDECL + '''<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
<w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:t></w:t></w:r></w:p>
<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1440" w:right="1800" w:bottom="1440" w:left="1800" w:header="851" w:footer="992" w:gutter="0"/></w:sectPr>
</w:body>
</w:document>'''

STYLES_XML = XMLDECL + '''<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/></w:style>
</w:styles>'''

CORE_XML = XMLDECL + '''<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<dc:creator></dc:creator><cp:lastModifiedBy></cp:lastModifiedBy>
<dcterms:created xsi:type="dcterms:W3CDTF">2026-01-01T00:00:00Z</dcterms:created>
<dcterms:modified xsi:type="dcterms:W3CDTF">2026-01-01T00:00:00Z</dcterms:modified>
</cp:coreProperties>'''

APP_XML = XMLDECL + '''<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"><Application>FinderNew</Application></Properties>'''

# ---------------------------------------------------------------- XLSX
RELS_XL_WORKBOOK = XMLDECL + '''<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>'''

XLSX_CT = XMLDECL + '''<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>'''

WORKBOOK_XML = XMLDECL + '''<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets>
</workbook>'''

SHEET_XML = XMLDECL + '''<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<sheetData/>
</worksheet>'''

XL_STYLES = XMLDECL + '''<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>
<fills count="1"><fill><patternFill patternType="none"/></fill></fills>
<borders count="1"><border/></borders>
<cellStyleXfs count="1"><xf/></cellStyleXfs>
<cellXfs count="1"><xf xfId="0"/></cellXfs>
</styleSheet>'''

# ---------------------------------------------------------------- PPTX
PPTX_CT = XMLDECL + '''<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>
<Override PartName="/ppt/slides/slide1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>
<Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>
<Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>
<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>'''

RELS_PPT = XMLDECL + '''<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide1.xml"/>
</Relationships>'''

RELS_SLIDE = XMLDECL + '''<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
</Relationships>'''

RELS_LAYOUT = XMLDECL + '''<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/>
</Relationships>'''

RELS_MASTER = XMLDECL + '''<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
</Relationships>'''

A = "http://schemas.openxmlformats.org/drawingml/2006/main"
P = "http://schemas.openxmlformats.org/presentationml/2006/main"
R = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"

PRESENTATION_XML = XMLDECL + f'''<p:presentation xmlns:p="{P}" xmlns:r="{R}">
<sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></sldMasterIdLst>
<sldIdLst><p:sldId id="256" r:id="rId2"/></sldIdLst>
<sldSz cx="12192000" cy="6858000"/>
</p:presentation>'''

SLIDE1_XML = XMLDECL + f'''<p:sld xmlns:p="{P}" xmlns:a="{A}">
<p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sld>'''

LAYOUT1_XML = XMLDECL + f'''<p:sldLayout xmlns:p="{P}" xmlns:a="{A}" type="blank" preserve="1">
<p:cSld name="Blank"><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sldLayout>'''

MASTER1_XML = XMLDECL + f'''<p:sldMaster xmlns:p="{P}" xmlns:a="{A}">
<p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld>
<p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>
<p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rId1" xmlns:r="{R}"/></p:sldLayoutIdLst>
</p:sldMaster>'''

# ---------------------------------------------------------------- write
write_zip(OUT / "blank.docx", {
    "[Content_Types].xml": CT_TYPES,
    "_rels/.rels": RELS_ROOT,
    "word/document.xml": DOC_XML,
    "word/_rels/document.xml.rels": RELS_WORD,
    "word/styles.xml": STYLES_XML,
    "docProps/core.xml": CORE_XML,
    "docProps/app.xml": APP_XML,
})

write_zip(OUT / "blank.xlsx", {
    "[Content_Types].xml": XLSX_CT,
    "_rels/.rels": RELS_ROOT,
    "xl/workbook.xml": WORKBOOK_XML,
    "xl/_rels/workbook.xml.rels": RELS_XL_WORKBOOK,
    "xl/worksheets/sheet1.xml": SHEET_XML,
    "xl/styles.xml": XL_STYLES,
    "docProps/core.xml": CORE_XML,
    "docProps/app.xml": APP_XML,
})

write_zip(OUT / "blank.pptx", {
    "[Content_Types].xml": PPTX_CT,
    "_rels/.rels": RELS_ROOT,
    "ppt/presentation.xml": PRESENTATION_XML,
    "ppt/_rels/presentation.xml.rels": RELS_PPT,
    "ppt/slides/slide1.xml": SLIDE1_XML,
    "ppt/slides/_rels/slide1.xml.rels": RELS_SLIDE,
    "ppt/slideLayouts/slideLayout1.xml": LAYOUT1_XML,
    "ppt/slideLayouts/_rels/slideLayout1.xml.rels": RELS_LAYOUT,
    "ppt/slideMasters/slideMaster1.xml": MASTER1_XML,
    "ppt/slideMasters/_rels/slideMaster1.xml.rels": RELS_MASTER,
    "docProps/core.xml": CORE_XML,
    "docProps/app.xml": APP_XML,
})

print("done")
