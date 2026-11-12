"""Generates Office/e-book test fixtures with independent libraries.

Run with a Python that has python-pptx, openpyxl, odfpy and xlwt:
    python tool/make_fixtures.py test/fixtures
All content is invented; no personal documents (CLAUDE.md rule 12).
"""
import io
import os
import struct
import sys
import zipfile
import zlib

out = sys.argv[1]
os.makedirs(out, exist_ok=True)


def png(w, h, rgb):
    raw = b''.join(b'\x00' + bytes(rgb) * w for _ in range(h))
    def chunk(t, d):
        return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))


# ---------------------------------------------------------------- PPTX
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE

prs = Presentation()
s = prs.slides.add_slide(prs.slide_layouts[0])
s.shapes.title.text = 'Quarterly Review'
s.placeholders[1].text = 'Regional operations, Q3'
s = prs.slides.add_slide(prs.slide_layouts[1])
s.shapes.title.text = 'Highlights'
body = s.placeholders[1].text_frame
body.text = 'Revenue up 12%'
for t in ['Two new offices', 'Hiring on track']:
    p = body.add_paragraph()
    p.text = t
    p.level = 1
s.notes_slide.notes_text_frame.text = 'Mention the Lahore office.'
s = prs.slides.add_slide(prs.slide_layouts[6])
box = s.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(1), Inches(1), Inches(3), Inches(1.5))
box.fill.solid()
box.fill.fore_color.rgb = RGBColor(0x1F, 0x3A, 0x4D)
box.text_frame.text = 'Boxed text'
s.shapes.add_shape(MSO_SHAPE.OVAL, Inches(5), Inches(1), Inches(2), Inches(2))
s.shapes.add_picture(io.BytesIO(png(40, 30, (200, 50, 50))), Inches(1), Inches(3.5), Inches(2), Inches(1.5))
tb = s.shapes.add_textbox(Inches(4), Inches(4), Inches(4), Inches(1))
r = tb.text_frame.paragraphs[0].add_run()
r.text = 'Big red'
r.font.size = Pt(40)
r.font.bold = True
r.font.color.rgb = RGBColor(0xC0, 0x39, 0x2B)
grp = s.shapes.add_group_shape()
grp.shapes.add_textbox(Inches(0.5), Inches(6), Inches(3), Inches(0.6)).text_frame.text = 'Grouped caption'
prs.save(os.path.join(out, 'deck.pptx'))

# ---------------------------------------------------------------- XLSX
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment

wb = Workbook()
ws = wb.active
ws.title = 'Budget'
ws.append(['Item', 'Amount', 'Date', 'Share'])
ws.append(['Rent', 45000, None, 0.25])
ws.append(['Salaries', 120000.5, None, 0.65])
ws['C2'] = __import__('datetime').date(2026, 3, 15)
ws['C2'].number_format = 'dd/mm/yyyy'
ws['B2'].number_format = '#,##0.00'
ws['B3'].number_format = '#,##0.00'
ws['D2'].number_format = '0%'
ws['D3'].number_format = '0%'
ws['B4'] = '=SUM(B2:B3)'
ws['A1'].font = Font(bold=True, color='C0392B')
ws['A1'].fill = PatternFill('solid', fgColor='FFF2CC')
ws.merge_cells('A6:C6')
ws['A6'] = 'Merged note'
ws['A6'].alignment = Alignment(horizontal='center')
ws.column_dimensions['A'].width = 24
ws.freeze_panes = 'B2'
ws2 = wb.create_sheet('Notes')
ws2['A1'] = 'Second sheet'
wb.save(os.path.join(out, 'budget.xlsx'))

# ---------------------------------------------------------------- XLS (BIFF8)
import xlwt
book = xlwt.Workbook()
sh = book.add_sheet('Legacy')
sh.write(0, 0, 'Name')
sh.write(0, 1, 'Value')
sh.write(1, 0, 'Alpha')
sh.write(1, 1, 42)
sh.write(2, 0, 'Beta')
sh.write(2, 1, 3.5)
book.add_sheet('Empty')
book.save(os.path.join(out, 'legacy.xls'))

# ---------------------------------------------------------------- ODT / ODS
from odf.opendocument import OpenDocumentText, OpenDocumentSpreadsheet
from odf.style import Style, TextProperties, ParagraphProperties
from odf.text import H, P, Span, List, ListItem
from odf.table import Table, TableRow, TableCell, TableColumn

doc = OpenDocumentText()
bold = Style(name='Bold', family='text')
bold.addElement(TextProperties(fontweight='bold'))
doc.automaticstyles.addElement(bold)
center = Style(name='Center', family='paragraph')
center.addElement(ParagraphProperties(textalign='center'))
doc.automaticstyles.addElement(center)
doc.text.addElement(H(outlinelevel=1, text='Meeting minutes'))
p = P(stylename=center)
p.addText('Attendees: ')
p.addElement(Span(stylename=bold, text='Ayesha, Bilal'))
doc.text.addElement(p)
lst = List()
for t in ['Approve budget', 'Plan visit']:
    li = ListItem()
    li.addElement(P(text=t))
    lst.addElement(li)
doc.text.addElement(lst)
t = Table(name='T1')
t.addElement(TableColumn(numbercolumnsrepeated=2))
for row in [['Task', 'Owner'], ['Report', 'Sana']]:
    tr = TableRow()
    for v in row:
        tc = TableCell()
        tc.addElement(P(text=v))
        tr.addElement(tc)
    t.addElement(tr)
doc.text.addElement(t)
doc.save(os.path.join(out, 'minutes.odt'))

ods = OpenDocumentSpreadsheet()
t = Table(name='Stock')
for row in [['Product', 'Qty'], ['Pens', 12], ['Paper', 500]]:
    tr = TableRow()
    for v in row:
        if isinstance(v, (int, float)):
            tc = TableCell(valuetype='float', value=v)
        else:
            tc = TableCell(valuetype='string')
        tc.addElement(P(text=str(v)))
        tr.addElement(tc)
    t.addElement(tr)
ods.spreadsheet.addElement(t)
ods.save(os.path.join(out, 'stock.ods'))

# ---------------------------------------------------------------- RTF
open(os.path.join(out, 'letter.rtf'), 'w', encoding='ascii').write(
    r'{\rtf1\ansi\ansicpg1252\deff0{\fonttbl{\f0 Calibri;}}{\colortbl;\red192\green57\blue43;}'
    r'{\*\generator Fixture;}\pard\qc\b\fs32 Notice\b0\par'
    r'\pard\fs22 Dear reader, this is \i italic\i0 , \ul underlined\ulnone\ and \cf1 red\cf0 .\par'
    'Price: 100 ' + chr(92) + 'u8364? and caf' + r'\'e9.\par'
    r'\trowd\cellx2000\cellx4000\intbl A1\cell B1\cell\row\pard After table.\par}')

# ---------------------------------------------------------------- Markdown
open(os.path.join(out, 'readme.md'), 'w', encoding='utf-8').write(
    '# Project notes\n\nSome **bold** and *italic* text with `code` and a [link](https://example.org).\n\n'
    '## Tasks\n\n- [x] Draft\n- [ ] Review\n  - Nested item\n\n1. First\n2. Second\n\n'
    '> Quoted line\n\n```\nlet x = 1;\n```\n\n| Name | Qty |\n|------|-----|\n| Pens | 12 |\n')

# ---------------------------------------------------------------- CSV
open(os.path.join(out, 'contacts.csv'), 'w', encoding='utf-8', newline='').write(
    'Name,City,Note\r\n"Khan, Ali",Lahore,"Said ""hello"""\r\nSara,Karachi,"Two\nlines"\r\n')

# ---------------------------------------------------------------- EPUB
epub = zipfile.ZipFile(os.path.join(out, 'story.epub'), 'w')
epub.writestr(zipfile.ZipInfo('mimetype'), 'application/epub+zip', compress_type=zipfile.ZIP_STORED)
epub.writestr('META-INF/container.xml',
              '<?xml version="1.0"?><container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
              '<rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles></container>')
epub.writestr('OEBPS/content.opf',
              '<?xml version="1.0"?><package xmlns="http://www.idpf.org/2007/opf" version="3.0">'
              '<metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>The Quiet Shop</dc:title><dc:creator>A. Writer</dc:creator></metadata>'
              '<manifest><item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>'
              '<item id="c1" href="text/ch1.xhtml" media-type="application/xhtml+xml"/>'
              '<item id="c2" href="text/ch2.xhtml" media-type="application/xhtml+xml"/>'
              '<item id="img" href="images/cover.png" media-type="image/png"/></manifest>'
              '<spine><itemref idref="c1"/><itemref idref="c2"/></spine></package>')
epub.writestr('OEBPS/nav.xhtml',
              '<?xml version="1.0"?><!DOCTYPE html><html xmlns="http://www.w3.org/1999/xhtml"><body><nav>'
              '<ol><li><a href="text/ch1.xhtml">Opening</a></li><li><a href="text/ch2.xhtml#s">The Visit</a></li></ol></nav></body></html>')
epub.writestr('OEBPS/text/ch1.xhtml',
              '<?xml version="1.0"?><!DOCTYPE html><html xmlns="http://www.w3.org/1999/xhtml"><body>'
              '<h1>Chapter One</h1><p>The shop was&nbsp;quiet &mdash; until <em>she</em> arrived.</p>'
              '<p><img src="../images/cover.png" alt="cover"/></p></body></html>')
epub.writestr('OEBPS/text/ch2.xhtml',
              '<?xml version="1.0"?><!DOCTYPE html><html xmlns="http://www.w3.org/1999/xhtml"><body>'
              '<h2 id="s">Chapter Two</h2><p>She bought a <strong>lamp</strong>.</p><ul><li>One</li><li>Two</li></ul></body></html>')
epub.writestr('OEBPS/images/cover.png', png(20, 30, (31, 58, 77)))
epub.close()

print('fixtures written to', out)
