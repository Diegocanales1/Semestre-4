// Cargando los csv para convertirlo a base de datos
LOAD CSV WITH HEADERS FROM "file:///got-s5-nodes.csv" AS row
CREATE (n:Person)
SET n = row
;
CREATE INDEX index_Page FOR (n:Person) ON (n.Id)
;
LOAD CSV FROM "file:///got-s5-edges.csv" AS row
MATCH (n:Person), (m:Person)
WHERE n.Id=row[0] and m.Id=row[1]
MERGE (n)-[r:RELATED{Weight:row[2]}]->(m)
SET r.Weight = toInteger(row[2])
SET r.Season = toInteger(row[3])
;
// preguntas de análisis básico del grafo

// 1. Imagen general del grafo 

// 2. Imagen del grafo completo

// 3. ¿Cuántos personajes hay en la base de datos?
MATCH (n:Person)
RETURN COUNT(n) AS Num_personajes
;
// 4. ¿Cuántas relaciones hay entre los personajes?
MATCH ()-[r:RELATED]->()
RETURN COUNT(r) AS Num_relaciones
;
// 5. ¿Cuál es el rango de peso de las relaciones?
MATCH ()-[r:RELATED]->()
RETURN MIN(r.Weight) AS Minimo, MAX(r.Weight) AS Maximo
;
// 6. ¿Cuál es el diámetro del grafo y que nos indica?
// Tiene diámetro de 6 esto significa que el camino más largo entre cualquier par de nodos en el grafo consta 
// de 6 relaciones. Esta medida nos proporciona información sobre la distancia máxima entre los nodos en el grafo.


// 7. (Utilizando Bloom) ¿Consulta personalizada sobre cual es el grafo del vecino a dos saltos de algun personaje como por ejemplo "Jon Snow"?
MATCH grafo = (p1:Person)-[*1..2]-(p2:Person)
WHERE p1.Label = $name_id
RETURN grafo
;
// 8. ¿Cuál es el personaje que tiene más relaciones?
MATCH (n:Person)-[r:RELATED]->()
RETURN n.Label AS Personaje, COUNT(r) AS Num_relaciones
ORDER BY Num_relaciones DESC
LIMIT 1
;
// 9. ¿Como podemos interpretar la densidad del grafo?
// El grafo cuenta con una densidad de 0.028 esto nos indica que existen el 2.8% de relaciones posibles 
// tomando en cuenta la cantidad de los nodos.

// 10. (Utilizando Bloom) ¿Consulta personalizada sobre el vecino a 1 salto de algun personaje como por ejemplo "Cersei"?
MATCH grafo = (p1:Person)-[*1..1]-(p2:Person)
WHERE p1.Label = $name_id
RETURN grafo
;

// 11. ¿Cuál es el personaje más importante de la red?
MATCH (n:Person)
RETURN n.Label AS Personaje, n.pageRank AS PageRank
ORDER BY n.pageRank DESC
LIMIT 1
;
// 12. ¿Cuál es el personaje que conecta la mayor cantidad de gente o actúa como "puente"? (Betweenness Centrality)
MATCH (n:Person)
RETURN n.Label AS Personaje, n.betweenness AS Betweenness
ORDER BY n.betweenness DESC
LIMIT 1
;
// 13. ¿Cuál es el personaje que busca relacionarse (por su parte) con la mayor cantidad de gente? (Mayor Out Degree Centrality)
MATCH (n:Person)
RETURN n.Label AS Personaje, n.OutDegree AS OutDegree
ORDER BY n.OutDegree DESC
LIMIT 1
;
// 14. ¿Cuál es el personaje que es más buscado por los demás? (Mayor In Degree Centrality)
MATCH (n:Person)
RETURN n.Label AS Personaje, n.InDegree AS InDegree
ORDER BY n.InDegree DESC
LIMIT 1
;
// 15. ¿Cuál es el personaje que es más cercano a los demás? (Mayor Closeness Centrality)
MATCH (n:Person)
RETURN n.Label AS Personaje, n.closeness AS Closeness
ORDER BY n.closeness DESC
LIMIT 1
;
// Centralidad

// Dregree

call gds.graph.project(
        'myDegreeGraph',
        'Person',
        {RELATED:
               {
                orientation: 'UNDIRECTED',
                Properties: 'Weight'
               }
        }

)
;
call gds.degree.write('myDegreeGraph',
        {writeProperty: 'Degree'}
)
yield centralityDistribution, nodePropertiesWritten
return centralityDistribution.min, centralityDistribution.max, centralityDistribution.mean, nodePropertiesWritten
;


// In_Degree

call gds.graph.project(
        'myINDegreeGraph',
        'Person',
        {RELATED:
               {
                orientation: 'REVERSE',
                Properties: 'Label'
               }
        }

)
;
call gds.degree.write('myINDegreeGraph',
        {writeProperty: 'InDegree'}
)
yield centralityDistribution, nodePropertiesWritten
return centralityDistribution.min, centralityDistribution.max, centralityDistribution.mean, nodePropertiesWritten
;
// Out_degree

call gds.graph.project(
        'myOutDegreeGraph',
        'Person',
        {RELATED:
               {
                orientation: 'NATURAL',
                Properties: 'Label'
               }
        }

)
;

call gds.degree.write('myOutDegreeGraph',
        {writeProperty: 'OutDegree'}
)
yield centralityDistribution, nodePropertiesWritten
return centralityDistribution.min, centralityDistribution.max, centralityDistribution.mean, nodePropertiesWritten
;

// Closeness

call gds.graph.project(
        'myClosenessGraph',
        'Person',
        'RELATED',
        {relationshipProperties: 'Weight'}
)
;
CALL gds.closeness.write('myClosenessGraph', { writeProperty: 'closeness' })
YIELD centralityDistribution, nodePropertiesWritten
RETURN centralityDistribution.min AS minimumScore, centralityDistribution.mean AS meanScore, nodePropertiesWritten
;

// PageRank

call gds.graph.project(
    'myPageRankGraph',
    'Person',
    'RELATED',
    {relationshipProperties:'Weight'}
)
;

call gds.pageRank.write(
        'myPageRankGraph',
        {
            maxIterations : 20,
            dampingFactor : 0.85,
            writeProperty : 'pageRank'
        }
)
YIELD nodePropertiesWritten, ranIterations
;

// Betweenes

call gds.graph.project(
        'myBetweenesGraph',
        'Person',
        'RELATED',
        {relationshipProperties: 'Weight'}
)
;

CALL gds.betweenness.write('myBetweenesGraph', { writeProperty: 'betweenness' })
YIELD centralityDistribution, nodePropertiesWritten
RETURN centralityDistribution.min AS minimumScore, centralityDistribution.mean AS meanScore, nodePropertiesWritten
;


/// Algoritmos de Comunidades

// Louvain Undirected
// Si tuviéramos que agrupar los personajes en comunidades dependiendo que tan relacionados están entre ellos y teniendo
// que seguir las direcciones que hay entre los grafos, ¿Cómo se verían? (Louvain undirected)

CALL gds.graph.project(
    'GraphLouvainUndirected',
    'Person',
    {RELATED:{orientation:'UNDIRECTED'}}
)
;
// 3. 

CALL gds.louvain.stream('GraphLouvainUndirected')
YIELD nodeId, communityId, intermediateCommunityIds
RETURN gds.util.asNode(nodeId).Label, communityId
ORDER BY communityId DESC
;
// 4. 

CALL gds.louvain.write('GraphLouvainUndirected', {writeProperty:'CommunityLouvain'})
YIELD communityCount, modularity 
;

// Louvain Directed

// Pregunta equivalente a esta base de datos de Game of Thrones
// Si tuviéramos que agrupar los personajes en comunidades dependiendo que tan relacionados están entre ellos y sin tener
// que seguir las direcciones que hay entre los grafos, ¿Cómo se verían? (Louvain directed)

CALL gds.graph.project(
    'GraphLouvainDirected',
    'Person',
    {RELATED:{orientation:'NATURAL'}}
)
;

// 3. 

CALL gds.louvain.stream('GraphLouvainDirected')
YIELD nodeId, communityId, intermediateCommunityIds
RETURN gds.util.asNode(nodeId).Label, communityId
ORDER BY communityId DESC
;
// 4. 

CALL gds.louvain.write('GraphLouvainDirected', {writeProperty:'CommunityLouvainDirected'})
YIELD communityCount, modularity 
;

// Que personajes quedarían en cada comunidad de acuerdo con la pregunta anterior? (Louvain DIRECTED distribución de personajes)
MATCH (a:Person)
WITH a.louvain_d AS communityId, COLLECT(DISTINCT a.Label) AS personajes, COUNT(DISTINCT a.Label) AS NumeroPersonajes 
RETURN communityId, NumeroPersonajes
ORDER BY NumeroPersonajes DESC 
;

// Codigo equivalente a esta base de datos de Game of Thrones
MATCH (p:Person)
RETURN p.CommunityLouvainDirected, COUNT(p.Label) AS cuantos_personajes, collect(p.Label) AS noms_personajes
ORDER BY cuantos_personajes DESC
;

// Si tuviéramos que agrupar los personajes en comunidades dependiendo que tan parecidos son entre ellos,
// ¿Cómo se verían? (LabelPropagation DIRECTED )

// 1. Sub grafo (no dirigido)
    CALL gds.graph.project(
        'MyDirectedGraphLP',
        'Person',
        {RELATED:{orientation:'NATURAL'}}
    )
;
    // 3. Implementar el algoritmo
    CALL gds.labelPropagation.stream('MyDirectedGraphLP')
    YIELD nodeId, communityId AS labelPropagation
    RETURN gds.util.asNode(nodeId).Label as Name, labelPropagation
    ORDER BY labelPropagation, Name 
;
    // 4. 
    CALL gds.labelPropagation.write('MyDirectedGraphLP',
    {writeProperty:'labelPropagationD'})
    YIELD communityCount, ranIterations,didConverge
;
// Que personajes quedarian en cada comunidad de acuerdo con la pregunta anterior? (label propagation DIRECTED distribucion de personajes)
MATCH (p:Person)
RETURN p.labelPropagationD, COUNT(p.Label) AS cuantos_personajes, collect(p.Label) AS noms_personajes
ORDER BY cuantos_personajes DESC
;
// Si tuviéramos que agrupar los personajes en comunidades dependiendo que tan parecidos son entre ellos y sin tener
// que seguir las direcciones de la red de personajes, ¿En cuantas comunidades se agruparian? (LabelPropagation UNDIRECTED)

// 1. Sub grafo (no dirigido)
    CALL gds.graph.project(
        'UndirectedGraphLP',
        'Person',
        {RELATED:{orientation:'UNDIRECTED'}}
    )
;
    // 3. Implementar el algoritmo
    CALL gds.labelPropagation.stream('UndirectedGraphLP')
    YIELD nodeId, communityId AS labelPropagation
    RETURN gds.util.asNode(nodeId).Label as Name, labelPropagation
    ORDER BY labelPropagation, Name 
;
    // 4. 
    CALL gds.labelPropagation.write('UndirectedGraphLP',
    {writeProperty:'CommunityLabelPropagationUndirected'})
    YIELD communityCount, ranIterations, didConverge
;

// Si tuvieramos que encontrar las rutas entre los personajes sin importar que sean las mas rapidas o directas, ¿Como se verian estas rutas? (WCC)
CALL gds.graph.project('GraphWCC', 'Person',
{
    RELATED: {
        orientation: 'NATURAL'
    }
})
;
CALL gds.wcc.stream('GraphWCC')
YIELD nodeId, componentId
RETURN gds.util.asNode(nodeId).Label AS Name, componentId
ORDER BY componentId, Name
;


CALL gds.wcc.write('GraphWCC', {
writeProperty: 'ComponentId_WCC'
})
YIELD nodePropertiesWritten, componentCount;

// Ahora queremos buscar las rutas entre los personajes pero que sean más directas o tome menos brincos entre ellos,
// ¿Cómo serían estas rutas? (SCC)

CALL gds.graph.project('GraphSCC', 'Person',
{
    RELATED: {
        orientation: 'NATURAL'
    }
})
;

CALL gds.scc.stream('GraphSCC', {})
YIELD nodeId, componentId
RETURN gds.util.asNode(nodeId).Label AS Name, componentId AS Component
ORDER BY Component DESC
;

CALL gds.scc.write('GraphSCC', {
writeProperty: 'ComponentId_SCC'
})
YIELD componentCount, componentDistribution
RETURN componentCount,componentDistribution.max as maxSetSize, componentDistribution.min as minSetSize
;

// ¿Cuántas conexiones existen en nuestra red de personajes si queremos analizarlos contando el número de conexiones entre 3 personajes? (Triangle Count)

CALL gds.graph.project(
  'Graph_TC_Undirected',
  'Person',
  {
    RELATED: {
      orientation: 'UNDIRECTED'
    }
  }
)
;
CALL gds.triangleCount.stream('Graph_TC_Undirected')
YIELD nodeId, triangleCount
RETURN gds.util.asNode(nodeId).Label AS name, triangleCount
ORDER BY triangleCount DESC
;

CALL gds.triangleCount.write('Graph_TC_Undirected', {
  writeProperty: 'CommunityTriangleCount'
})
YIELD globalTriangleCount, nodeCount
;

// Cual es el personaje que a traves de el se crean mas conexiones triangulares? (Triangle Count)
CALL gds.triangleCount.stream('Graph_TC_Undirected')
YIELD nodeId, triangleCount
RETURN gds.util.asNode(nodeId).Label AS name, triangleCount
ORDER BY triangleCount DESC
;
// Anade un atributo coloreado con su valor correspondiente a cada nodo Person

// Aplicar el algoritmo

CALL gds.graph.project(
    'Graph_K1Coloring_Undirected',
    'Person',
    {
        RELATED : {
            orientation: 'UNDIRECTED'
        }
    }
)
;
CALL gds.beta.k1coloring.stream('Graph_K1Coloring_Undirected')
YIELD nodeId, color
RETURN gds.util.asNode(nodeId).Label AS name, color
ORDER BY name
;
// Aplicar el algoritmo
CALL gds.k1coloring.stream('Graph_K1Coloring_Undirected')
YIELD nodeId, color

;
// Agregar la propiedad
CALL gds.k1coloring.write('Graph_K1Coloring_Undirected', {writeProperty: 'color'})
YIELD nodeCount, colorCount, ranIterations, didConverge, configuration, preProcessingMillis, computeMillis, writeMillis
;

// Revisar los resultados
// Aplicar el algoritmo
CALL gds.k1coloring.stream('Graph_K1Coloring_Undirected')
YIELD nodeId, color
RETURN color, COLLECT(gds.util.asNode(nodeId).Label) AS names
ORDER BY color
;

// Preguntas Centralidad

// Pregunta técnica: ¿Cuál es el personaje con mayor Closeness Centrality?
// Pregunta de negocio: ¿Qué personajes son los que tienen más cercanía para interactuar con otros personajes?
// Respuesta : "Tycho", "Selwyn", "Jaqen", "Jaime", "Barristan", "Rickon", "Derryk", "Denys", "Doran", "Eddison"
// "Bronn", "Catelyn", "Madame", "Rhaenyra", "Davos", "Daenerys", "Walder"

match(p:Person)
return p.closeness as Closeness, p.Label as Nombre
order by Closeness desc
limit 17
;
// Pregunta técnica: ¿Cuál es el personaje con más Degree?
// Pregunta de negocio: ¿Cuál es el personaje que se relaciona más?
// Respuesta : "Cersei"

match (p:Person)
return p.Degree as degree, p.Label as Nombre
order by degree desc
;
// Pregunta técnica: ¿Cuál es el personaje con más OutDegree?
// Pregunta de negocio: ¿Cuál es el personaje que busca relacionarse más con otras personas?
// Respuesta: "Cersei"

match (p:Person)
return p.OutDegree as Outdegree, p.Label as Nombre
order by Outdegree desc
;
// Respuesta técnica: ¿Cuáles personajes con más InDegree?
// Pregunta de negocio: ¿Cuál es el personaje que es más solicitado por otros personajes?
// Respuesta: "Stannis"

match (p:Person)
return p.InDegree as Indegree, p.Label as Nombre
order by Indegree desc
;
// Pregunta técnica: ¿Cuáles personajes con mayor Pagerank?
// Pregunta de negocio: ¿Qué personajes se pueden considerar más influyentes de la temporada?
// Respuesta: "Stannis"

match(p:Person)
return p.pageRank as pagerank, p.Label as Nombre
order by pagerank desc  
;

// Pregunta técnica: ¿Cuáles son los 5 personajes con mayor Betweenes Centrality?
// Pregunta de negocio: ¿Los 5 personajes que son más importantes para la comunicación entre distintas casas o regiones durante esta temporada?
// Respuesta: "Petyr"

match(p:Person)
return p.betweenness as Betweenness, p.Label as Nombre
order by Betweenness desc
limit 5 
;
// Pregunta técnica: ¿Quién tiene el Betwenness Centrality más bajo?
// Pregunta de negocio: ¿Qué personajes parecen estar mas apartado o no ser tan importante a la hora de interactuar entre las casas? 
// Respuesta: "Aegon","Aerys","Alliser","Areo","Arya", "Strumpet" y otros 63

match(p:Person)
return p.betweenness as Betweenness, p.Label as Nombre
order by Betweenness asc
limit 69
;
// Pregunta técnica: ¿Con base a las medidas de centralidad qué personajes pueden ser los más importantes?  
// Pregunta de negocio: ¿Qué personajes tienen más potencial para convertirse líderes o puntos de referencia?
// Respuesta: "Stannis", "Cersei", "Petyr"


// Pregunta técnica: ¿Cómo se pueden utilizar las medidas de centralidad para mejorar la comunicación y la colaboración en la red social?
// Pregunta de negocio: ¿Qué se debe de hacer para mejorar la comunicación entre los 7 reinos?   


// Filtrar las comunidades para hacer las medidas de centralidad por cada reino
// Comunidad 73 = "Stannis"
MATCH (p:Person)
WHERE p.communitylouvain = 73
return p.communitylouvain as IdComunidad, p.Degree as Degree, p.Label as Nombre
order by Degree desc
;
MATCH (p:Person)
WHERE p.communitylouvain = 73
return p.communitylouvain as IdComunidad, p.betweenness as Betwenness, p.Label as Nombre
order by Betwenness desc
;
MATCH (p:Person)
WHERE p.communitylouvain = 73
return p.communitylouvain as IdComunidad, p.pageRank as PageRank, p.Label as Nombre
order by PageRank desc
;
// Comunidad 83 = "Petyr"

MATCH (p:Person)
WHERE p.communitylouvain = 83
return p.communitylouvain as IdComunidad, p.Degree as Degree, p.Label as Nombre
order by Degree desc
;
MATCH (p:Person)
WHERE p.communitylouvain = 83
return p.communitylouvain as IdComunidad, p.betweenness as Betwenness, p.Label as Nombre
order by Betwenness desc
;
MATCH (p:Person)
WHERE p.communitylouvain = 83
return p.communitylouvain as IdComunidad, p.pageRank as PageRank, p.Label as Nombre
order by PageRank desc
;
// Comunidad 30 = "Tyrion"

MATCH (p:Person)
WHERE p.communitylouvain = 30
return p.communitylouvain as IdComunidad, p.Degree as Degree, p.Label as Nombre
order by Degree desc
;
MATCH (p:Person)
WHERE p.communitylouvain = 30
return p.communitylouvain as IdComunidad, p.betweenness as Betwenness, p.Label as Nombre
order by Betwenness desc
;
MATCH (p:Person)
WHERE p.communitylouvain = 30
return p.communitylouvain as IdComunidad, p.pageRank as PageRank, p.Label as Nombre
order by PageRank desc
;
// Comunidad 72 = "Cersei"

MATCH (p:Person)
WHERE p.communitylouvain = 72
return p.communitylouvain as IdComunidad, p.Degree as Degree, p.Label as Nombre
order by Degree desc
;
MATCH (p:Person)
WHERE p.communitylouvain = 72
return p.communitylouvain as IdComunidad, p.betweenness as Betwenness, p.Label as Nombre
order by Betwenness desc
;
MATCH (p:Person)
WHERE p.communitylouvain = 72
return p.communitylouvain as IdComunidad, p.pageRank as PageRank, p.Label as Nombre
order by PageRank desc
;
// Comunidad 69 = "Jaime"

MATCH (p:Person)
WHERE p.communitylouvain = 69
return p.communitylouvain as IdComunidad, p.Degree as Degree, p.Label as Nombre
order by Degree desc
;
MATCH (p:Person)
WHERE p.communitylouvain = 69
return p.communitylouvain as IdComunidad, p.betweenness as Betwenness, p.Label as Nombre
order by Betwenness desc
;
MATCH (p:Person)
WHERE p.communitylouvain = 69
return p.communitylouvain as IdComunidad, p.pageRank as PageRank, p.Label as Nombre
order by PageRank desc
;
// Comunidad 80 = "Meryn"

MATCH (p:Person)
WHERE p.communitylouvain = 80
return p.communitylouvain as IdComunidad, p.Degree as Degree, p.Label as Nombre
order by Degree desc
;
MATCH (p:Person)
WHERE p.communitylouvain = 80
return p.communitylouvain as IdComunidad, p.betweenness as Betwenness, p.Label as Nombre
order by Betwenness desc
;
MATCH (p:Person)
WHERE p.communitylouvain = 80
return p.communitylouvain as IdComunidad, p.pageRank as PageRank, p.Label as Nombre
order by PageRank desc
;

// ver que personajes de los seleccionados tiene una relacion fuerte con personajes de otros reinos 

MATCH (p1:Person)-[r:RELATED]-(p2:Person)
WHERE p1.Label IN ["Stannis", "Petyr", "Tyrion", "Cersei", "Jaime", "Meryn", "Wolkan"]
  AND p2.communitylouvain <> p1.communitylouvain
RETURN p1.communitylouvain as IDComunidad1, p1.Label AS PersonajeLocal, p2.communitylouvain as IDComunidad2, p2.Label AS PersonajeForaneo, r.Weight AS Weight
ORDER BY Weight DESC
;
// Peso de relación entre los personajes de la comunidad 73

MATCH (p1:Person)-[r:RELATED]-(p2:Person)
WHERE p1.communitylouvain = 73
  AND p2.communitylouvain = 73
RETURN p1.Label AS Personaje1, p2.Label AS Personaje2, r.Weight AS Weight
ORDER BY Weight DESC
;
// Peso de relación entre los personajes de la comunidad 83

MATCH (p1:Person)-[r:RELATED]-(p2:Person)
WHERE p1.communitylouvain = 83
  AND p2.communitylouvain = 83
RETURN p1.Label AS Personaje1, p2.Label AS Personaj2, r.Weight AS Weight
ORDER BY Weight DESC
;
// Peso de relación entre los personajes de la comunidad 30

MATCH (p1:Person)-[r:RELATED]-(p2:Person)
WHERE p1.communitylouvain = 30
  AND p2.communitylouvain = 30
RETURN p1.Label AS Personaje1, p2.Label AS Personaje2, r.Weight AS Weight
ORDER BY Weight DESC
;
// Peso de relación entre los personajes de la comunidad 72

MATCH (p1:Person)-[r:RELATED]-(p2:Person)
WHERE p1.communitylouvain = 72
  AND p2.communitylouvain = 72
RETURN p1.Label AS Personaje1, p2.Label AS Personaje2, r.Weight AS Weight
ORDER BY Weight DESC
;
// Peso de relación entre los personajes de la comunidad 69

MATCH (p1:Person)-[r:RELATED]-(p2:Person)
WHERE p1.communitylouvain = 69
  AND p2.communitylouvain = 69
RETURN p1.Label AS Personaje1, p2.Label AS Personaje2, r.Weight AS Weight
ORDER BY Weight DESC
;
// Peso de relación entre los personajes de la comunidad 80

MATCH (p1:Person)-[r:RELATED]-(p2:Person)
WHERE p1.communitylouvain = 80
  AND p2.communitylouvain = 80
RETURN p1.Label AS Personaje1, p2.Label AS Personaje2, r.Weight AS Weight
ORDER BY Weight DESC
;
