import httpClient
import xmlparser
import xmltree

proc getLatestYarn*(): string =
    var client = newHttpClient()
    var yarrn_metadata_raw = client.getContent("https://maven.modmuss50.me/net/fabricmc/yarn/maven-metadata.xml")
    var parsed_metadata = parseXml(yarrn_metadata_raw)
    return parsed_metadata.child("versioning").child("latest").innerText()
when isMainModule:
    echo getLatestYarn()