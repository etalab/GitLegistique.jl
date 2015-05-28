# GitLegistique

Convert Git diffs of French law articles to legislative drafting ("amendements" in French).

Trying to follow http://www.legifrance.gouv.fr/Droit-francais/Guide-de-legistique

[![Build Status](https://travis-ci.org/etalab/GitLegistique.jl.svg?branch=master)](https://travis-ci.org/etalab/GitLegistique.jl)

# Requirements

- [Julia language](http://julialang.org/)
- https://github.com/steeve/france.code-civil (branch "everything")

# Example

Generate an "amendement" between the n-2 commit and the last one:

    julia src/GitLegistique.jl -o HEAD~2 -n HEAD^ /path/to/france.code-civil/ Amendement1.md

This outputs:

```
Article 1
----
L'alinéa 3 de l'article L758-1 est remplacé par les disposition suivantes :

« Lorsque le conseil d'administration de la Fondation nationale des sciences
politiques examine le budget de l'Institut d'études politiques de Paris et fixe
les droits de scolarité pour les formations menant à des diplômes propres de
l'établissement, des représentants des étudiants élus au conseil de direction de
l'institut y participent avec voix délibérative. »
```
