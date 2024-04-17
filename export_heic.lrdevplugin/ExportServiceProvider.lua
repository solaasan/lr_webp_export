local LrTasks = import 'LrTasks'
local LrDialogs = import 'LrDialogs'
local LrPathUtils = import 'LrPathUtils'
local LrExportSession = import 'LrExportSession'
local LrFileUtils = import 'LrFileUtils'
local exportServiceProvider = {}


exportServiceProvider.processRenderedPhotos = function(functionContext, exportContext)
    local exportSession = exportContext.exportSession
    local nPhotos = exportSession:countRenditions()

    for i, rendition in exportSession:renditions() do
        local success, pathOrMessage = rendition:waitForRender()
        if success then
            local heicPath = LrPathUtils.replaceExtension(pathOrMessage, "heic")
            local command = string.format("sips -s format heic  -s formatOptions 70 %s --out %s", pathOrMessage, heicPath)

            local result = LrTasks.execute(command)
            if result ~= 0 then
                LrDialogs.showError("Failed to convert to HEIC.")
            else
                LrFileUtils.delete(pathOrMessage)
            end
        else
            LrDialogs.showError("Error rendering photo: " .. tostring(pathOrMessage))
        end
    end
end

return exportServiceProvider
