import json
import tables
import typetraits
import streams
when not defined(js) and not defined(android) and not defined(ios):
    import os

import nimx.image
import nimx.types
import nimx.pathutils
import nimx.matrixes

import rod.rod_types
import rod.component
import rod.component.material
import rod.component.sprite
import rod.component.light
import rod.component.text_component
import rod.component.mesh_component
import rod.component.particle_system

type Serializer* = ref object
    savePath*: string

proc `%`*[T](elements: openArray[T]): JsonNode =
    result = newJArray()
    for elem in elements:
        result.add(%elem)

proc vectorToJNode[T](vec: T): JsonNode =
    result = newJArray()
    for k, v in vec:
        result.add(%v)

proc `%`*[I: static[int], T](vec: TVector[I, T]): JsonNode =
    result = vectorToJNode(vec)

proc colorToJNode(color:Color): JsonNode =
    result = newJArray()
    for k, v in color.fieldPairs:
        result.add( %v )

proc getRelativeResourcePath(s: Serializer, path: string): string =
    var resourcePath = path
    when not defined(js) and not defined(android) and not defined(ios):
        resourcePath = parentDir(s.savePath)

    result = relativePathToPath(resourcePath, path)
    echo "save path = ", resourcePath, "  relative = ", result

method getComponentData(s: Serializer, c: Component): JsonNode =
    result = newJObject()

method getComponentData(s: Serializer, c: Text): JsonNode =
    result = newJObject()
    result.add("text", %c.text)
    result.add("color", colorToJNode(c.color))
    result.add("shadowX", %c.shadowX)
    result.add("shadowY", %c.shadowY)
    result.add("shadowColor", colorToJNode(c.shadowColor))
    result.add("Tracking Amount", %c.trackingAmount)

method getComponentData(s: Serializer, c: Sprite): JsonNode =
    result = newJObject()
    result.add("currentFrame", %c.currentFrame)

    var imagesNode = newJArray()
    result.add("fileNames", imagesNode)
    for img in c.images:
        imagesNode.add( %s.getRelativeResourcePath(img.filePath()) )


method getComponentData(s: Serializer, c: LightSource): JsonNode =
    result = newJObject()
    result.add("ambient", %c.lightAmbient)
    result.add("diffuse", %c.lightDiffuse)
    result.add("specular", %c.lightSpecular)
    result.add("constant", %c.lightConstant)

method getComponentData(s: Serializer, c: ParticleSystem): JsonNode =
    result = newJObject()
    result.add("duration", %c.duration)
    result.add("isLooped", %c.isLooped)
    result.add("birthRate", %c.birthRate)
    result.add("lifetime", %c.lifetime)
    result.add("startVelocity", %c.startVelocity)
    result.add("randVelocityFrom", %c.randVelocityFrom)
    result.add("randVelocityTo", %c.randVelocityTo)
    result.add("randRotVelocityFrom", %c.randRotVelocityFrom)
    result.add("randRotVelocityTo", %c.randRotVelocityTo)
    result.add("startScale", %c.startScale)
    result.add("dstScale", %c.dstScale)
    result.add("randScaleFrom", %c.randScaleFrom)
    result.add("randScaleTo", %c.randScaleTo)
    result.add("startAlpha", %c.startAlpha)
    result.add("dstAlpha", %c.dstAlpha)
    result.add("startColor", %c.startColor)
    result.add("dstColor", %c.dstColor)
    result.add("gravity", %c.gravity)
    result.add("texture", %s.getRelativeResourcePath(c.texture.filePath()))

method getComponentData(s: Serializer, c: MeshComponent): JsonNode =
    result = newJObject()

    result.add("emission", colorToJNode(c.material.emission))
    result.add("ambient", colorToJNode(c.material.ambient))
    result.add("diffuse", colorToJNode(c.material.diffuse))
    result.add("specular", colorToJNode(c.material.specular))
    result.add("shininess", %c.material.shininess)
    result.add("reflectivity", %c.material.reflectivity)
    result.add("rim_density", %c.material.rim_density)

    result.add("culling", %c.material.bEnableBackfaceCulling)
    result.add("light", %c.material.isLightReceiver)
    result.add("blend", %c.material.blendEnable)
    result.add("depth_test", %c.material.depthEnable)
    result.add("wireframe", %c.material.isWireframe)
    result.add("RIM", %c.material.isRIM)
    result.add("sRGB_normal", %c.material.isNormalSRGB)

    if not c.material.albedoTexture.isNil:
        result.add("albedoTexture",  %s.getRelativeResourcePath(c.material.albedoTexture.filePath()))
    if not c.material.glossTexture.isNil:
        result.add("glossTexture",  %s.getRelativeResourcePath(c.material.glossTexture.filePath()))
    if not c.material.specularTexture.isNil:
        result.add("specularTexture",  %s.getRelativeResourcePath(c.material.specularTexture.filePath()))
    if not c.material.normalTexture.isNil:
        result.add("normalTexture",  %s.getRelativeResourcePath(c.material.normalTexture.filePath()))
    if not c.material.bumpTexture.isNil:
        result.add("bumpTexture",  %s.getRelativeResourcePath(c.material.bumpTexture.filePath()))
    if not c.material.reflectionTexture.isNil:
        result.add("reflectionTexture",  %s.getRelativeResourcePath(c.material.reflectionTexture.filePath()))
    if not c.material.falloffTexture.isNil:
        result.add("falloffTexture",  %s.getRelativeResourcePath(c.material.falloffTexture.filePath()))
    if not c.material.maskTexture.isNil:
        result.add("maskTexture",  %s.getRelativeResourcePath(c.material.maskTexture.filePath()))

    var data = c.getVBDataFromVRAM()

    proc needsKey(name: string): bool =
        case name
        of "vertex_coords": return c.vboData.vertInfo.numOfCoordPerVert > 0 or false
        of "tex_coords": return c.vboData.vertInfo.numOfCoordPerTexCoord > 0  or false
        of "normals": return c.vboData.vertInfo.numOfCoordPerNormal > 0  or false
        of "tangents": return c.vboData.vertInfo.numOfCoordPerTangent > 0  or false

    template addInfo(name: string, f: typed) =
        if needsKey(name):
            result[name] = %f(c, data)

    addInfo("vertex_coords", extractVertCoords)
    addInfo("tex_coords", extractTexCoords)
    addInfo("normals", extractNormals)
    addInfo("tangents", extractTangents)

    var ib = c.getIBDataFromVRAM()
    var ibNode = newJArray()
    result.add("indices", ibNode)
    for v in ib:
        ibNode.add(%int32(v))


proc getNodeData(s: Serializer, n: Node): JsonNode =
    result = newJObject()
    result.add("name", %n.name)
    result.add("translation", vectorToJNode(n.translation))
    result.add("scale", vectorToJNode(n.scale))
    result.add("rotation", vectorToJNode(n.rotation))
    result.add("alpha", %n.alpha)

    if not n.components.isNil:
        var componentsNode = newJObject()
        result.add("components", componentsNode)

        for k, v in n.components:
            var jcomp: JsonNode
            jcomp = s.getComponentData( v )

            if not jcomp.isNil:
                componentsNode.add(k, jcomp)

    var childsNode = newJArray()
    result.add("children", childsNode)
    for child in n.children:
        childsNode.add( s.getNodeData(child) )


proc save*(s: Serializer, n: Node, path: string) =
    when not defined(js) and not defined(android) and not defined(ios):
        s.savePath = path
        var nd = s.getNodeData(n)
        var str = nd.pretty()

        var fs = newFileStream(path, fmWrite)
        if fs.isNil:
            echo "WARNING: Resource can not open: ", path
        else:
            fs.write(str)
            fs.close()
            echo "save at path ", path
    else:
        echo "serializer::save don't support js"
