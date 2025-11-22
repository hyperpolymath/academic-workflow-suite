# Assets Directory

This directory contains icons and images for the AWAP Office Add-in.

## Required Icons

The Office Add-in manifest requires icons in the following sizes:

### Add-in Icons

- **icon-16.png**: 16x16 pixels - Ribbon icon (small)
- **icon-32.png**: 32x32 pixels - Ribbon icon (medium), Add-in tile
- **icon-64.png**: 64x64 pixels - High-resolution add-in tile
- **icon-80.png**: 80x80 pixels - Ribbon icon (large)

### Icon Guidelines

1. **Format**: PNG with transparent background
2. **Style**: Simple, recognizable at small sizes
3. **Colors**: Use brand colors consistently
4. **Background**: Transparent (alpha channel)
5. **Content**: Clear visual that represents the AWAP brand

### Creating Icons

You can create icons using:

- **Adobe Illustrator/Photoshop**: Professional design tools
- **Figma**: Free online design tool
- **Canva**: Easy-to-use design platform
- **GIMP**: Free image editor

### Design Recommendations

For the AWAP add-in, consider:

- Academic-themed imagery (books, graduation cap, documents)
- Professional color scheme (blues, grays)
- Clear symbol that represents assessment/feedback
- Consistent with Microsoft Office design language

### Example Icon Creation

Using Figma or similar tool:

1. Create a 80x80px artboard
2. Design your icon with 8px padding on all sides
3. Export at multiple sizes:
   - 16x16
   - 32x32
   - 64x64
   - 80x80
4. Save as PNG with transparency

### Placeholder Icons

For development, you can use placeholder icons:

```bash
# Using ImageMagick (if installed)
convert -size 16x16 xc:#0078d4 icon-16.png
convert -size 32x32 xc:#0078d4 icon-32.png
convert -size 64x64 xc:#0078d4 icon-64.png
convert -size 80x80 xc:#0078d4 icon-80.png
```

Or use online icon generators:
- https://www.favicon-generator.org/
- https://realfavicongenerator.net/

### Current Status

⚠️ **Placeholder icons needed** - Add your custom icons before deploying to production.

For now, you can use solid color placeholders or find free icons from:
- https://www.flaticon.com/
- https://icons8.com/
- https://www.iconfinder.com/
- https://fontawesome.com/

### License

Ensure any icons you use have appropriate licenses for commercial use.
