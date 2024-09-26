# WebP Exporter for Lightroom Classic
This is a Lightroom plugin that can change the output file to WebP format.

Although Lightroom currently supports WebP images, it does not support output in WebP format. This plug-in will solve this problem.

Note: Currently only Lightroom Classic and MacOS are supported. Additionally it expects imagemagick to be present on your system, presumably installed via Homebrew. If you have it installed elsewhere or by other means update the path field in the export dialog

# Add to LR
* Open the Lightroom Classic Plugin Manager.
* Click “Add”.
* Select this plugin.

# Usage
* Select the photos you want to export
* Open the export dialog box and select "Export to WebP" at the top.
* Set the export image format to TIFF.
* Start export

Because this plug-in first exports to an intermediate format and then converts it to WebP, it is recommended that the intermediate format be selected as TIFF to ensure the best image quality. The resulting WebP image will be 12 bit by default unless you select 8 bit. Most places seem to handle 12 bit no issue, 12 bit webp seems a sane compromise between quality and file size until more places support jpeg-xl.

# Credit where due
Basically a modified version of https://github.com/fengshenx/lr_heic_export but updated to use imagemagick instead of sips, and webp instead of heic. Basic checking as added as well to avoid overwriting previously exported images due to the intermediary file.
