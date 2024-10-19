local mapFunctions = {
    padding = 10,
    zoomMin = 10,
    zoomMax = 24
}

mapFunctions.zoomAndCentreMapToBounds = function(mapElement, x, y, x2, y2)

    local map = mapElement
    local api = map.mapAPI

    local wx = x - mapFunctions.padding
    local wy = y - mapFunctions.padding
    local wx2 = x2 + mapFunctions.padding
    local wy2 = y2 + mapFunctions.padding

    local width = wx2 - wx
    local height = wy2 - wy

    local bound = math.max(width, height)
    local viewport = math.max(map:getWidth(), map:getHeight())

    api:centerOn(x + (width / 2), y + (height / 2))

    -- kludge to get the zoom level right
    for zoom = mapFunctions.zoomMax, mapFunctions.zoomMin, -.5 do
        api:setZoom(zoom)
        if bound * api:getWorldScale() < viewport then
            -- box now fits in viewport at this zoom level
            return zoom
        end
    end

    api:setZoom(mapFunctions.zoomMax)
    return mapFunctions.zoomMax

end

mapFunctions.euclideanDistance = function(point1, point2)
    local dx = point1[1] - point2[1]
    local dy = point1[2] - point2[2]
    return math.sqrt(dx * dx + dy * dy)
end

mapFunctions.proximityClustering = function(points, distanceThreshold)
    local clusters = {}
    local visited = {}

    -- Helper function to recursively group points
    local function groupPoints(point, cluster)
        visited[point] = true
        table.insert(cluster, point)

        for _, otherPoint in ipairs(points) do
            if not visited[otherPoint] and mapFunctions.euclideanDistance(point, otherPoint) <= distanceThreshold then
                groupPoints(otherPoint, cluster)
            end
        end
    end

    -- Iterate over all points
    for _, point in ipairs(points) do
        if not visited[point] then
            local cluster = {}
            groupPoints(point, cluster)
            table.insert(clusters, cluster)
        end
    end

    return clusters
end

return mapFunctions
