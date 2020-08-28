import httpClient
import xmlparser
import xmltree
import zip/zipfiles
import streams
import msgpack
import strutils
import os

proc getLatestYarn*(): string =
    let client = newHttpClient()
    let yarrn_metadata_raw = client.getContent("https://maven.modmuss50.me/net/fabricmc/yarn/maven-metadata.xml")
    let parsed_metadata = parseXml(yarrn_metadata_raw)
    return parsed_metadata.child("versioning").child("latest").innerText()

proc getYarnUnmergedTiny2*(yarn_version: string): Stream =
    let client = newHttpClient()
    let zip_data = client.getContent("https://maven.modmuss50.me/net/fabricmc/yarn/" & yarn_version & "/yarn-" & yarn_version & "-v2.jar")
    var z: ZipArchive
    z.fromBuffer(zip_data)
    let tiny_stream = newStringStream()
    z.extractFile("mappings/mappings.tiny", tiny_stream)
    tiny_stream.setPosition(0)
    return tiny_stream

proc tinyToNano*(tiny: Stream): StringStream =
    assert tiny.readLine() == "tiny\t2\t0\tintermediary\tnamed"
    result = newStringStream()
    var classes = newSeq[tuple[key: Msg, val: Msg]](0)
    var hasClass = false
    var currentClassIntermediary: Msg
    var currentClassNamed: Msg
    var currentMethods: seq[tuple[key: Msg, val: Msg]]
    var currentFields: seq[tuple[key: Msg, val: Msg]]
    for line in tiny.lines():
        case line[0]:
            of 'c':
                if hasClass:
                    classes.add((currentClassIntermediary, @[("c".wrap, currentClassNamed), ("m".wrap, currentMethods.wrap), ("f".wrap, currentFields.wrap)].wrap))
                else:
                    hasClass = true
                currentMethods = newSeq[tuple[key: Msg, val: Msg]](0)
                currentFields = newSeq[tuple[key: Msg, val: Msg]](0)
                let strings = line.split('\t')
                currentClassIntermediary = strings[1].wrap
                currentClassNamed = strings[2].wrap
            of '\t':
                let strings = line.split('\t')
                case strings[1]:
                    of "m":
                        currentMethods.add((strings[4].wrap, strings[3].wrap))
                    of "f":
                        currentFields.add((strings[4].wrap, strings[3].wrap))
                    of "", "c":
                        discard # Parameters And JavaDocs
                    else:
                        echo "Unexpected Class Thing Char In Tiny File"
                        quit(1)
            else:
                echo "Unexpected Line Staring Char In Tiny File"
                quit(1)
    result.pack(classes)
    result.setPosition(0)

when isMainModule:
    var f = open("build/mappings.nylonnano", fmWrite)
    let latest_yarn = getLatestYarn()
    echo latest_yarn
    f.write(tinyToNano(getYarnUnmergedTiny2(latest_yarn)).data)