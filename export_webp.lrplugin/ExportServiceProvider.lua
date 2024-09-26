local LrTasks = import 'LrTasks'
local LrDialogs = import 'LrDialogs'
local LrPathUtils = import 'LrPathUtils'
local LrExportSession = import 'LrExportSession'
local LrFileUtils = import 'LrFileUtils'
local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrProgressScope = import 'LrProgressScope'

local exportServiceProvider = {}

exportServiceProvider.exportPresetFields = {
    { key = 'imageQuality', default = 70 },
    { key = 'magickPath', default = '/opt/homebrew/bin/magick' }, -- Default path to magick
    { key = 'bitDepth', default = '12' }, -- Option for 8 or 12 bit output
}


-- Force the export to render as TIFF
exportServiceProvider.allowFileFormats = { 'TIFF' }

-- Force sRGB
exportServiceProvider.allowColorSpaces = { 'sRGB' }

--- No Video
exportServiceProvider.canExportVideo = false

-- Hide the File and Video Settings section to prevent users from changing the format
exportServiceProvider.hideSections = { 'fileSettings', 'video' }

exportServiceProvider.startDialog = function(propertyTable)
    local f = LrView.osFactory()
    local bind = LrView.bind
    local share = LrView.share

    -- Ensure imageQuality is an integer
    propertyTable:addObserver('imageQuality', function()
        propertyTable.imageQuality = math.floor(propertyTable.imageQuality + 0.5)
    end)

    local contents = f:column {
        bind_to_object = propertyTable,
        f:row {
            f:static_text {
                title = "Image Quality:",
                alignment = 'right',
                width = share 'label_width',
            },
            f:slider {
                value = bind 'imageQuality',
                min = 0,
                max = 100,
                width_in_chars = 20,
                fill_horizontal = 1,
            },
            f:edit_field {
                value = bind 'imageQuality',
                width_in_chars = 3,
            },
        },
        f:row {
            f:static_text {
                title = "Bit Depth:",
                alignment = 'right',
                width = share 'label_width',
            },
            f:popup_menu {
                value = bind 'bitDepth',
                items = {
                    { title = '8-bit', value = '8' },
                    { title = '12-bit', value = '12' },
                },
                width_in_chars = 10,
            },
        },
        f:row {
            f:static_text {
                title = "Path to ImageMagick:",
                alignment = 'right',
                width = share 'label_width',
            },
            f:edit_field {
                value = bind 'magickPath',
                width_in_chars = 30,
                fill_horizontal = 1,
            },
            f:static_text {
                title = "Default is '/opt/homebrew/bin/magick' (change if installed elsewhere)",
            },
        },
    }

    return contents
end

exportServiceProvider.sectionsForTopOfDialog = function(viewFactory, propertyTable)
    local f = viewFactory

    -- Ensure imageQuality is an integer
    propertyTable:addObserver('imageQuality', function()
        propertyTable.imageQuality = math.floor(propertyTable.imageQuality + 0.5)
    end)

    return {
        {
            title = "WEBP Export Options",
            f:row {
                f:static_text {
                    title = "Image Quality:",
                    alignment = 'right',
                    width = LrView.share 'label_width',
                },
                f:slider {
                    value = LrView.bind 'imageQuality',
                    min = 0,
                    max = 100,
                    width_in_chars = 20,
                    fill_horizontal = 1,
                },
                f:edit_field {
                    value = LrView.bind 'imageQuality',
                    width_in_chars = 3,
                },
            },
            f:row {
                f:static_text {
                    title = "Bit Depth:",
                    alignment = 'right',
                    width = LrView.share 'label_width',
                },
                f:popup_menu {
                    value = LrView.bind 'bitDepth',
                    items = {
                        { title = '8-bit', value = '8' },
                        { title = '12-bit', value = '12' },
                    },
                    width_in_chars = 10,
                },
            },
            f:row {
                f:static_text {
                    title = "Path to ImageMagick:",
                    alignment = 'right',
                    width = LrView.share 'label_width',
                },
                f:edit_field {
                    value = LrView.bind 'magickPath',
                    width_in_chars = 30,
                    fill_horizontal = 1,
                },
                f:static_text {
                    title = "Default is '/opt/homebrew/bin/magick' (change if installed elsewhere)",
                },
            },
        },
    }
end

-- Function to override export settings
exportServiceProvider.exportPresetFieldsForPlugin = function()
    return {
        -- Force TIFF format
        { key = 'LR_export_bitDepth', value = 16 },
        { key = 'LR_format', value = 'TIFF' },
        { key = 'LR_tiff_compressionMethod', value = 'compressionMethod_None' },
        { key = 'LR_tiff_byteOrder', value = 'byteOrder_LittleEndian' },
    }
end

-- Function to generate a unique filename if file exists
local function generateUniqueFilename(filePath)
    local base, extension = LrPathUtils.removeExtension(filePath), LrPathUtils.extension(filePath)
    local index = 1
    local newFilePath = filePath
    while LrFileUtils.exists(newFilePath) do
        newFilePath = string.format("%s_%d.%s", base, index, extension)
        index = index + 1
    end
    return newFilePath
end

exportServiceProvider.processRenderedPhotos = function(functionContext, exportContext)
    local exportSession = exportContext.exportSession
    local nPhotos = exportSession:countRenditions()
    local progressScope = LrProgressScope({
        title = 'Exporting to WEBP',
        functionContext = functionContext
    })

    local imageQuality = exportContext.propertyTable.imageQuality or 70
    local magickPath = exportContext.propertyTable.magickPath or '/opt/homebrew/bin/magick'
    local bitDepth = exportContext.propertyTable.bitDepth or '12'

    for i, rendition in exportSession:renditions{ stopIfCanceled = true } do
        progressScope:setPortionComplete(i - 1, nPhotos)

        local success, pathOrMessage = rendition:waitForRender()
        if success then
            local webpPath = LrPathUtils.replaceExtension(pathOrMessage, "webp")
            -- Check if the webp file already exists, if so, generate a unique filename
            if LrFileUtils.exists(webpPath) then
                webpPath = generateUniqueFilename(webpPath)
            end

            local command = string.format('%s %q -depth %s -quality %d %q', magickPath, pathOrMessage, bitDepth, imageQuality, webpPath)

            -- Execute the command
            local result = LrTasks.execute(command)
            if result ~= 0 then
                LrDialogs.showError("Failed to convert to WEBP.")
                rendition:renditionIsDone(false, "Failed to convert to WEBP.")
            else
                LrFileUtils.delete(pathOrMessage)
                rendition:renditionIsDone(true)
            end
        else
            LrDialogs.showError("Error rendering photo: " .. tostring(pathOrMessage))
            rendition:renditionIsDone(false, "Error rendering photo: " .. tostring(pathOrMessage))
        end

        progressScope:setPortionComplete(i, nPhotos)
    end

    progressScope:done()
end

return exportServiceProvider