LOAD CSV WITH HEADERS FROM "file:///nodosOpenFlight.csv" AS row
CREATE (n:Airport)
SET n = row
;
CREATE INDEX index_Articulo FOR (n:Airport) ON (n.Id)
;
LOAD CSV FROM "file:///enlacesOpenFlight.csv" AS row
MATCH (n:Airport), (m:Airport)
WHERE n.Id=row[0] and m.Id=row[1]
MERGE (n)-[:CONNECTED]->(m)
;
MATCH (a:Airport)
SET a.longitude = toFloat(a.longitude), a.latitude = toFloat(a.latitude)
;

//1.
MATCH   
    (a:Airport{Label:"Buffalo"}), 
    (b:Airport{Label:"Charlotte"})
WITH 
    point({longitude:a.longitude, latitude:a.latitude}) as p1, 
    point({longitude:b.longitude, latitude:b.latitude}) as p2, 
    a.Label as origen, 
    b.label as destino  
WITH 
    point.distance(p1,p2)/1000 as dist
MATCH 
    (a:Airport{Label:"Buffalo"}), 
    (b:Airport{Label:"Charlotte"})
MERGE 
    (a)-[r:DISTANCE{geodesicDistance:dist}]->(b)
RETURN a,r,b
// 2.
;
MATCH   
    (a:Airport{Label:"Salt Lake City"}), 
    (b:Airport{Label:"Charlotte"})
WITH 
    point({longitude:a.longitude, latitude:a.latitude}) as p1, 
    point({longitude:b.longitude, latitude:b.latitude}) as p2, 
    a.Label as origen, 
    b.label as destino  
WITH 
    point.distance(p1,p2)/1000 as dist
MATCH 
    (a:Airport{Label:"Salt Lake City"}), 
    (b:Airport{Label:"Charlotte"})
MERGE 
    (a)-[r:DISTANCE{geodesicDistance:dist}]->(b)
RETURN a,r,b
;
// 3.
MATCH   
    (a:Airport{Label:"Buffalo"}), 
    (b:Airport{Label:"Boston"})
WITH 
    point({longitude:a.longitude, latitude:a.latitude}) as p1, 
    point({longitude:b.longitude, latitude:b.latitude}) as p2, 
    a.Label as origen, 
    b.label as destino  
WITH 
    point.distance(p1,p2)/1000 as dist
MATCH 
    (a:Airport{Label:"Buffalo"}), 
    (b:Airport{Label:"Boston"})
MERGE 
    (a)-[r:DISTANCE{geodesicDistance:dist}]->(b)
RETURN a,r,b
;
//4. 
MATCH   
    (a:Airport{Label:"Charlotte"}), 
    (b:Airport{Label:"Boston"})
WITH 
    point({longitude:a.longitude, latitude:a.latitude}) as p1, 
    point({longitude:b.longitude, latitude:b.latitude}) as p2, 
    a.Label as origen, 
    b.label as destino  
WITH 
    point.distance(p1,p2)/1000 as dist
MATCH 
    (a:Airport{Label:"Charlotte"}), 
    (b:Airport{Label:"Boston"})
MERGE 
    (a)-[r:DISTANCE{geodesicDistance:dist}]->(b)
RETURN a,r,b
//5.
MATCH   
    (a:Airport{Label:"Charlotte"}), 
    (b:Airport{Label:"Birmingham"})
WITH 
    point({longitude:a.longitude, latitude:a.latitude}) as p1, 
    point({longitude:b.longitude, latitude:b.latitude}) as p2, 
    a.Label as origen, 
    b.label as destino  
WITH 
    point.distance(p1,p2)/1000 as dist
MATCH 
    (a:Airport{Label:"Charlotte"}), 
    (b:Airport{Label:"Birmingham"})
MERGE 
    (a)-[r:DISTANCE{geodesicDistance:dist}]->(b)
RETURN a,r,b
;
// 6.
MATCH   
    (a:Airport{Label:"Charlotte"}), 
    (b:Airport{Label:"Atlanta"})
WITH 
    point({longitude:a.longitude, latitude:a.latitude}) as p1, 
    point({longitude:b.longitude, latitude:b.latitude}) as p2, 
    a.Label as origen, 
    b.label as destino  
WITH 
    point.distance(p1,p2)/1000 as dist
MATCH 
    (a:Airport{Label:"Charlotte"}), 
    (b:Airport{Label:"Atlanta"})
MERGE 
    (a)-[r:DISTANCE{geodesicDistance:dist}]->(b)
RETURN a,r,b
;
// 7.
MATCH   
    (a:Airport{Label:"Atlanta"}), 
    (b:Airport{Label:"Madrid"})
WITH 
    point({longitude:a.longitude, latitude:a.latitude}) as p1, 
    point({longitude:b.longitude, latitude:b.latitude}) as p2, 
    a.Label as origen, 
    b.label as destino  
WITH 
    point.distance(p1,p2)/1000 as dist
MATCH 
    (a:Airport{Label:"Atlanta"}), 
    (b:Airport{Label:"Madrid"})
MERGE 
    (a)-[r:DISTANCE{geodesicDistance:dist}]->(b)
RETURN a,r,b
;
// 8.
MATCH   
    (a:Airport{Label:"Boston"}), 
    (b:Airport{Label:"Buffalo"})
WITH 
    point({longitude:a.longitude, latitude:a.latitude}) as p1, 
    point({longitude:b.longitude, latitude:b.latitude}) as p2, 
    a.Label as origen, 
    b.label as destino  
WITH 
    point.distance(p1,p2)/1000 as dist
MATCH 
    (a:Airport{Label:"Boston"}), 
    (b:Airport{Label:"Buffalo"})
MERGE 
    (a)-[r:DISTANCE{geodesicDistance:dist}]->(b)
RETURN a,r,b
;
// 9.
MATCH   
    (a:Airport{Label:"Buffalo"}), 
    (b:Airport{Label:"Tampa"})
WITH 
    point({longitude:a.longitude, latitude:a.latitude}) as p1, 
    point({longitude:b.longitude, latitude:b.latitude}) as p2, 
    a.Label as origen, 
    b.label as destino  
WITH 
    point.distance(p1,p2)/1000 as dist
MATCH 
    (a:Airport{Label:"Buffalo"}), 
    (b:Airport{Label:"Tampa"})
MERGE 
    (a)-[r:DISTANCE{geodesicDistance:dist}]->(b)
RETURN a,r,b


// Subgrafo

// Undirected
call gds.graph.project(
        'myUndirectedGraph',
        'Airport',
        {DISTANCE:
           {
                orientation: 'UNDIRECTED',
                Properties: 'geodesicDistance'
           }        
        }
)
;
// Directed

call gds.graph.project(
        'myDirectedGraph',
        'Airport',
        {DISTANCE:
           {
                orientation: 'NATURAL',
                Properties: 'geodesicDistance'
           }        
        }
)
;

// Delta

// Undirected
MATCH (source:Airport{Label:'Buffalo'})
CALL
gds.allShortestPaths.delta.write('myUndirectedGraph',
{
sourceNode: source,
relationshipWeightProperty: 'geodesicDistance',
writeRelationshipType:
'PATH_Buffalo_Undirected',
writeNodeIds: true,
writeCosts: true
})
YIELD relationshipsWritten
RETURN relationshipsWritten
;
// Directed

MATCH (source:Airport{Label:'Buffalo'})
CALL
gds.allShortestPaths.delta.write('myDirectedGraph',
{
sourceNode: source,
relationshipWeightProperty: 'geodesicDistance',
writeRelationshipType:
'PATH_Buffalo_directed',
writeNodeIds: true,
writeCosts: true
})
YIELD relationshipsWritten
RETURN relationshipsWritten
;


// Dijkstra

match (source: Airport{Label:'Salt Lake City'}),
(target: Airport{Label:'Tampa'})
call
gds.shortestPath.dijkstra.write('myUndirectedGraph',
{
        sourceNode: source,
        targetNode: target,
        relationshipWeightProperty: 'geodesicDistance',
        writeRelationshipType: 'PATH_Und_Salt_Lake_City_to_Tampa',
        writeNodeIds: true,
        writeCosts: true
})
yield relationshipsWritten
return relationshipsWritten
;

// Random Walk

MATCH (a:Airport)
WHERE a.Label IN ['Salt Lake City', 'Birmingham']
WITH COLLECT(a) as sourceNodes
CALL gds.randomWalk.stream(
  'myDirectedGraph',
  {
    sourceNodes: sourceNodes,
    walkLength: 3,
    walksPerNode: 1,
    randomSeed: 42,
    concurrency: 1
  }
)
YIELD nodeIds, path
RETURN nodeIds, [node IN nodes(path) | node.Label ] AS pages
;

// Minimum 

MATCH (source:Airport{Label:'Tampa'})
CALL gds.beta.spanningTree.write
(
'myUndirectedGraph', {
sourceNode: id(source),
relationshipWeightProperty: 'geodesicDistance',
writeProperty: 'writeCost',
writeRelationshipType: 'MINST'
}
)
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;
;
MATCH path = (n:Airport {Label: 'Tampa'})-[:MINST*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel).Label AS Source, endNode(rel).Label AS Destination, rel.writeCost AS Cost
;
// Depth

MATCH (source:Airport{Label:'Salt Lake City'})
CALL gds.dfs.stream('myDirectedGraph', {
sourceNode: source,
maxDepth: 1
})
YIELD path
RETURN path
;

// 3.5 Neodash (Mapa)

match (a:Airport{Label:"Salt Lake City"})-[:PATH_Und_Salt_Lake_City_to_Tampa]-(b)
return a, b
;

// 3.6 
// Degree

call gds.degree.write('myUndirectedGraph',
        {writeProperty: 'Degree'}
)
yield centralityDistribution, nodePropertiesWritten
return centralityDistribution.min, centralityDistribution.max, centralityDistribution.mean, nodePropertiesWritten
;
match (a:Airport)
return a.Degree as Degree, count(DISTINCT a) as cuantos_aeropuertos, a.Label as Ciudad
order by Degree desc

// Minimum 
MATCH (source:Airport{Label:'Charlotte'})
CALL gds.beta.spanningTree.write
(
'myUndirectedGraph', {
sourceNode: id(source),
relationshipWeightProperty: 'geodesicDistance',
writeProperty: 'writeCost',
writeRelationshipType: 'MINST2'
}
)
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;

// 3.7

// Quiero usar mis kilometros de viaje de mi TDC y tengo 3000, 
// cuales son los destinos que podria visitar desde Miami sin gastar un solo dolar
// Que aeropurtos se puede alcanzar desde Miami con una distancia geodesica menor a 3000
MATCH (a:Airport{Label:"Charlotte"})<-[r:DISTANCE]-(destination:Airport)
WHERE r.geodesicDistance < 3000
RETURN a,r,destination
;

//Estoy pensando en viajar desde Atlanta a algún nuevo destino no más lejano a 10000 km,
//quiero saber que países puedo alcanzar con escalas y cuales puedo alcanzar sin necesidad 
//de escalas ¿Que aeropuertos se puede alcanzar desde Atlanta con una distancia geodésica menor a 10000?

MATCH (atlanta:Airport{Label:"Atlanta"})-[r:DISTANCE]-(destination:Airport)
WHERE r.geodesicDistance < 10000
RETURN atlanta,r,destination
;

//Que aeropurtos se puede alcanzar desde Atlanta con una distancia geodesica menor a 10000,
//y con la relacion connected

MATCH (atlanta:Airport{Label:"Atlanta"})-[r:CONNECTED]->(destination:Airport)
WHERE EXISTS {MATCH (atlanta)-[d:DISTANCE]->(destination) WHERE d.geodesicDistance < 10000}
RETURN atlanta,r,destination
;

//Soy de Bufalo y quisiera saber cuál es el aeropuerto más cercano al que pueda viajar
MATCH (:Airport {Label: 'Buffalo'})-[r:DISTANCE]->(airport:Airport)
RETURN airport.Label as Destiny, r.geodesicDistance AS distance
ORDER BY distance ASC
LIMIT 1
;

//¿Cuál es la distancia geodésica entre Charlotte y Birmingham?
MATCH (a1:Airport{Label:"Charlotte"})-[r:DISTANCE]->(a2:Airport{Label:"Birmingham"})
RETURN r.geodesicDistance as Distance
;

//¿Cuál es el aeropuerto más conectado en términos de destinos directos desde los Estados Unidos?
MATCH (a:Airport)-[:CONNECTED]->(b:Airport)
WHERE a.country = 'United States' AND b.country <> 'United States'
RETURN a.Label AS Aeropuerto_Origen, count(b) AS Destinos_Directos
ORDER BY Destinos_Directos DESC
LIMIT 1
;