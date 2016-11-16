<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
java.nio.charset.StandardCharsets,
java.nio.file.Files
" %>
<!DOCTYPE html>
<html>
  <head>
    <title>Alix, expérimentations pédagogiques de fouille de textes</title>
    <link rel="stylesheet" type="text/css" href="alix.css" />
  </head>
  <body>
    <article>
      <h1>Alix</h1>
      <p>
        Alix est une <a href="https://github.com/oeuvres/Alix">librairie logiciel libre</a> pour la fouille lexicale, 
activement développée en ce moment par 
<a onclick="this.href='mailto'+'\x3A'+'frederic.glorieux'+'\x40'+'fictif.org'" href="#">Frédéric Glorieux</a> 
dans le contexte  du <a href="http://obvil.paris-sorbonne.fr/developpements/alix">LABEX OBVIL</a>.
Cette démonstration en ligne est pour l’instant destinée à la mise au point des fonctionnalités
        avec les chercheurs intéressés. 
        Le cœur est un lemmatiseur pour le français, programmé dans le langage Java, sans dépendances.
        Il existe d’autres lemmatiseurs, mais ils n’ont pas été développé en contexte littéraire, si bien qu‘aucun 
        de ceux que nous avons testé se comporte correctement avec les vers de la poésie ou du théâtre.
Par ailleurs, ce moteur s’accommode très bien du XML, il va être prochainement utilisé pour du pré-balisage
de noms propres.
Il est aussi pensé pour s’adapter aux textes “sauvages”, comme les corpus d’OCR
brut, avec beaucoup de fautes à la page. 
La précision n’empêche pas la rapidité (~4 s. pour 10 millions de mots, 42 romans de Dumas),
obtenue par des structures de données optimisées pour le traitement de la langue (fenêtre glissante de mots, dictionnaires arborescents, vecteurs de mots…).
Cette base solide permet de développer des vues nouvelles pour l’exploration des textes, la liste ci-dessous est destinée à s”étendre.
Cette installation propose différents corpus littéraire de test, dans l’objectif d’étalonner les chiffres 
sur les auteurs les plus connus.
      </p>
      <ul>
        <li><a href="lem.jsp">Le lemmatiseur du pauvre</a></li>
        <li><a href="freq.jsp">Mots fréquents, selon la catégorie grammaticale, comparés à Frantext</a></li>
        <li><a href="comp.jsp">Comparer deux tableaux lexicaux</a></li>
        <li><a href="gn.jsp">Adjectifs ante ou post posés</a></li>
      </ul>
    </article>
  </body>
</html>
