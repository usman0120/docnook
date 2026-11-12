"""Writes a plain multi-page PDF with text and an outline, for viewer tests.
Usage: python tool/make_test_pdf.py OUT.pdf [pages]"""
import sys

out, pages = sys.argv[1], int(sys.argv[2]) if len(sys.argv) > 2 else 120
objs = []
def add(body):
    objs.append(body)
    return len(objs)

font = add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>')
bold = add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>')
pages_id = len(objs) + 1 + 2 * pages + 1  # placeholder, fixed below
page_ids, content_ids = [], []
words = ('invoice ledger budget office logistics quarterly region staffing review '
         'summary contract delivery payment schedule report').split()
for i in range(1, pages + 1):
    lines = [f'BT /F2 22 Tf 72 740 Td (Chapter {(i - 1) // 10 + 1} - Page {i}) Tj ET']
    y = 700
    for n in range(28):
        text = ' '.join(words[(i * 7 + n * 3 + k) % len(words)] for k in range(11))
        lines.append(f'BT /F1 11 Tf 72 {y} Td ({text}) Tj ET')
        y -= 22
    if i == 42:
        lines.append('BT /F1 11 Tf 72 60 Td (The secret word is marmalade.) Tj ET')
    stream = '\n'.join(lines)
    content_ids.append(add(f'<< /Length {len(stream)} >>\nstream\n{stream}\nendstream'))
    page_ids.append(add('PAGE'))
pages_id = add('PAGES')
chapters = list(range(1, pages + 1, 10))
outline_root = len(objs) + 1
item_ids = [outline_root + 1 + k for k in range(len(chapters))]
add(f'<< /Type /Outlines /First {item_ids[0]} 0 R /Last {item_ids[-1]} 0 R /Count {len(chapters)} >>')
for k, start in enumerate(chapters):
    prev = f'/Prev {item_ids[k-1]} 0 R ' if k else ''
    nxt = f'/Next {item_ids[k+1]} 0 R ' if k + 1 < len(chapters) else ''
    add(f'<< /Title (Chapter {k + 1}) /Parent {outline_root} 0 R {prev}{nxt}'
        f'/Dest [{page_ids[start - 1]} 0 R /XYZ 0 792 0] >>')
catalog = add(f'<< /Type /Catalog /Pages {pages_id} 0 R /Outlines {outline_root} 0 R /PageMode /UseOutlines >>')
info = add('(DocNook test document)')
objs[info - 1] = '<< /Title (DocNook test document) /Producer (DocNook fixtures) >>'
for idx, pid in enumerate(page_ids):
    objs[pid - 1] = (f'<< /Type /Page /Parent {pages_id} 0 R /MediaBox [0 0 612 792] '
                     f'/Resources << /Font << /F1 {font} 0 R /F2 {bold} 0 R >> >> /Contents {content_ids[idx]} 0 R >>')
objs[pages_id - 1] = f'<< /Type /Pages /Kids [{" ".join(f"{p} 0 R" for p in page_ids)}] /Count {pages} >>'

data = bytearray(b'%PDF-1.4\n')
offsets = []
for n, body in enumerate(objs, 1):
    offsets.append(len(data))
    data += f'{n} 0 obj\n{body}\nendobj\n'.encode('latin-1')
xref = len(data)
data += f'xref\n0 {len(objs) + 1}\n0000000000 65535 f \n'.encode()
for off in offsets:
    data += f'{off:010d} 00000 n \n'.encode()
data += (f'trailer\n<< /Size {len(objs) + 1} /Root {catalog} 0 R /Info {info} 0 R >>\n'
         f'startxref\n{xref}\n%%EOF\n').encode()
open(out, 'wb').write(data)
print(out, len(data), 'bytes', pages, 'pages')
