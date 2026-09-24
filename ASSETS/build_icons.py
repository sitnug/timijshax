"""Build the original timijshax 64px line-icon atlas. Requires Pillow."""
from pathlib import Path
from PIL import Image, ImageDraw

NAMES = ['sword', 'eye', 'globe', 'zap', 'wind', 'cog', 'settings', 'bot',
         'play', 'monitor', 'save', 'search', 'check', 'chevron-up', 'key', 'move',
         'move-diagonal-2', 'crosshair', 'layers', 'terminal', 'shield', 'pin', 'x', 'chevron-right']
# Shapes use a shared 32-unit grid and are rendered at 4x before downsampling.
S = 4
atlas = Image.new('RGBA', (8*32*S, 3*32*S))
for i, name in enumerate(NAMES):
    tile = Image.new('RGBA', (32*S,32*S)); d=ImageDraw.Draw(tile)
    def line(points): d.line([(int(x*S),int(y*S)) for x,y in points],fill='white',width=2*S,joint='curve')
    def box(x1,y1,x2,y2): d.rectangle((x1*S,y1*S,x2*S,y2*S),outline='white',width=2*S)
    def circle(x1,y1,x2,y2): d.ellipse((x1*S,y1*S,x2*S,y2*S),outline='white',width=2*S)
    if name=='sword': line([(8,25),(23,10),(26,6),(21,7),(6,22)]); line([(7,17),(15,25)]); line([(6,26),(10,22)])
    elif name=='eye': line([(3,16),(9,9),(23,9),(29,16),(23,23),(9,23),(3,16)]); circle(12,12,20,20)
    elif name=='globe': circle(4,4,28,28); line([(4,16),(28,16)]); line([(16,4),(10,11),(10,21),(16,28),(22,21),(22,11),(16,4)])
    elif name=='zap': line([(18,3),(6,18),(15,18),(12,29),(27,12),(18,12),(18,3)])
    elif name=='wind': line([(3,9),(25,9),(29,13),(25,17),(8,17)]); line([(3,24),(20,24),(24,20)]); line([(3,17),(5,17)])
    elif name=='cog': box(9,9,23,23); circle(13,13,19,19); [line(p) for p in [[(13,3),(13,9)],[(20,3),(20,9)],[(13,23),(13,29)],[(20,23),(20,29)],[(3,13),(9,13)],[(3,20),(9,20)],[(23,13),(29,13)],[(23,20),(29,20)]]]
    elif name=='settings': [line([(5,y),(27,y)]) for y in [8,16,24]]; box(9,5,13,11); box(21,13,25,19); box(13,21,17,27)
    elif name=='bot': box(5,10,27,25); line([(16,10),(16,4)]); circle(14,2,18,6); line([(10,15),(10,18)]); line([(22,15),(22,18)]); line([(12,22),(20,22)])
    elif name=='play': line([(10,5),(27,16),(10,27),(10,5)])
    elif name=='monitor': box(3,5,29,23); line([(16,23),(16,28)]); line([(10,28),(22,28)]); line([(8,12),(12,16),(8,20)]); line([(16,19),(23,19)])
    elif name=='save': line([(6,4),(24,4),(28,8),(28,28),(4,28),(4,4),(6,4)]); box(10,4,22,12); box(9,19,23,28)
    elif name=='search': circle(4,4,22,22); line([(21,21),(29,29)])
    elif name=='check': line([(5,16),(12,23),(27,8)])
    elif name=='chevron-up': line([(6,21),(16,11),(26,21)])
    elif name=='key': circle(4,4,17,17); line([(15,15),(28,28)]); line([(21,21),(25,17)]); line([(25,25),(29,21)])
    elif name=='move': line([(16,3),(16,29)]); line([(3,16),(29,16)]); [line(p) for p in [[(11,8),(16,3),(21,8)],[(11,24),(16,29),(21,24)],[(8,11),(3,16),(8,21)],[(24,11),(29,16),(24,21)]]]
    elif name=='move-diagonal-2': line([(6,26),(26,6)]); line([(6,16),(6,26),(16,26)]); line([(16,6),(26,6),(26,16)])
    elif name=='crosshair': circle(7,7,25,25); [line(p) for p in [[(16,2),(16,10)],[(16,22),(16,30)],[(2,16),(10,16)],[(22,16),(30,16)]]]
    elif name=='layers': line([(3,11),(16,4),(29,11),(16,18),(3,11)]); line([(3,17),(16,24),(29,17)]); line([(3,23),(16,30),(29,23)])
    elif name=='terminal': box(3,5,29,27); line([(7,11),(12,16),(7,21)]); line([(16,21),(24,21)])
    elif name=='shield': line([(16,3),(27,7),(25,21),(16,29),(7,21),(5,7),(16,3)]); line([(11,15),(15,19),(22,11)])
    elif name=='pin': circle(7,3,25,21); circle(13,9,19,15); line([(8,19),(16,29),(24,19)])
    elif name=='x': line([(7,7),(25,25)]); line([(25,7),(7,25)])
    elif name=='chevron-right': line([(11,6),(21,16),(11,26)])
    atlas.alpha_composite(tile, ((i%8)*32*S,(i//8)*32*S))
atlas.resize((512,192),Image.Resampling.LANCZOS).save(Path(__file__).with_name('icons-v2.png'))
