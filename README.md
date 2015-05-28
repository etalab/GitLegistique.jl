# GitLegistique

Convert Git diffs of French law articles to legislative drafting ("amendements" in French).

Trying to follow http://www.legifrance.gouv.fr/Droit-francais/Guide-de-legistique

[![Build Status](https://travis-ci.org/etalab/GitLegistique.jl.svg?branch=master)](https://travis-ci.org/etalab/GitLegistique.jl)

# Requirements

- [Julia language](http://julialang.org/)
- https://github.com/steeve/france.code-civil (branch "everything")

# Example

Generate an "amendement" between the n-5 commit and the last one:

    julia src/GitLegistique.jl -o HEAD~5 -n HEAD /path/to/france.code-civil/ Amendement1.md

This outputs:

```markdown
Article 1
----
Les articles A751-1, A751-10, A751-11, A751-12, A751-2, A751-3, A751-4, A751-5,
A751-6, A751-7, A751-8 et A751-9 sont abrogés.

Article 2
----
L'alinéa 3 de l'article L758-1 est remplacé par les dispositions suivantes :

« Lorsque le conseil d'administration de la Fondation nationale des sciences
politiques examine le budget de l'Institut d'études politiques de Paris et fixe
les droits de scolarité pour les formations menant à des diplômes propres de
l'établissement, des représentants des étudiants élus au conseil de direction de
l'institut y participent avec voix délibérative. »


Article 3
----
L'alinéa 1 de l'article R821-5 est remplacé par les dispositions suivantes :

« L'allocation aux adultes handicapés prévue à l'article L. 821-1 et le
complément de ressources prévu à l'article L. 821-1-1 sont accordés par la
commission des droits et de l'autonomie des personnes handicapées pour une
période au moins égale à un an et au plus égale à cinq ans. Si le handicap n'est
pas susceptible d'une évolution favorable, la période d'attribution de
l'allocation et la période d'attribution du complément de ressources peuvent
excéder cinq ans sans toutefois dépasser dix ans.

L'allocation aux adultes handicapés prévue à l'article L. 821-2 est accordée par
ladite commission pour une période de un à deux ans. La période d'attribution de
l'allocation peut excéder deux ans sans toutefois dépasser cinq ans, si le
handicap et la restriction substantielle et durable pour l'accès à l'emploi
prévue au troisième alinéa de cet article ne sont pas susceptibles d'une
évolution favorable au cours de la période d'attribution. »


Article 4
----
L'alinéa 12 de l'article D821-1-2 est remplacé par les dispositions suivantes :

« 3° La restriction est durable dès lors qu'elle est d'une durée prévisible d'au
moins un an à compter du dépôt de la demande d'allocation aux adultes
handicapés, même si la situation médicale du demandeur n'est pas stabilisée. La
restriction substantielle et durable pour l'accès à l'emploi est reconnue pour
une durée de un à cinq ans. »

[... skipped ...]
```
