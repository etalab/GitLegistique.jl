# GitLegistique

Convert Git diffs of French law (in Markdown format) to legislative drafting ("légistique" in French).

Trying to follow: http://www.legifrance.gouv.fr/Droit-francais/Guide-de-legistique

This script is highly experimental.

<!-- [![Build Status](https://travis-ci.org/etalab/GitLegistique.jl.svg?branch=master)](https://travis-ci.org/etalab/GitLegistique.jl) -->

# Requirements

- [Julia language](http://julialang.org/)
- [French codes of law converted to Git/Markdown format by Steeve Morin](https://github.com/steeve/france.code-civil) (branch "everything")

# Example

Generate the legislative drafting of the difference between the n-5 commit and the latest one:

    julia src/GitLegistique.jl -o HEAD~10 -n HEAD /path/to/france.code-civil/ amendement1.md

This creates the `amendement1.md` file containing something like:

```markdown
Article 1
----
Les articles A751-1, A751-10, A751-11, A751-12, A751-2, A751-3, A751-4, A751-5,
A751-6, A751-7, A751-8 et A751-9 sont abrogés.

[...]


Article 3
----
L'alinéa 24 de l'article R217-3 est remplacé par les dispositions suivantes :

« Toutefois, l'amende ne peut excéder 1 500 euros en cas de défaut de
présentation des documents exigibles par la réglementation. Ces plafonds peuvent
être doublés en cas de nouveau manquement de même nature commis dans le délai
d'un an à compter de la notification de la décision du préfet ;

j) Des mesures restrictives d'exploitation ou des mesures correctives ou de
nature à compenser la non-conformité relevée, prévues au VI de l'article R.
213-7 du code de l'aviation civile, »


Article 4
----
Il est inséré un article R330-12-2 ainsi rédigé :

« Art. R330-12-2 – I. - En cas de menace pour la sécurité nationale présentant à
la fois un caractère d'urgence et de particulière gravité, le ministre chargé de
l'aviation civile peut suspendre, pour une durée qui ne peut excéder un mois,
l'autorisation d'exploiter des services de transport aérien entre un aérodrome
étranger et le territoire national, accordée à une entreprise de transport
aérien en application de l'article R. 330-6 du code de l'aviation civile.

II. - Dans les mêmes circonstances, le préfet de région du lieu du principal
établissement de l'entreprise de transport aérien peut suspendre, pour une durée
qui ne peut excéder un mois, l'autorisation d'exploiter des services de
transport aérien entre un aérodrome étranger et le territoire national, accordée
à cette entreprise en application de l'article R. 330-19-1 du code de l'aviation
civile. »


Article 5
----
À l'alinéa 3 de l'article L758-1, le mot « cinq » est remplacé par le mot
« des ».


Article 6
----
À l'alinéa 1 de l'article D423-12, les mots « selon le mode de comptabilisation
des ressources affectées » sont supprimés.

[...]


Article 10
----
À l'alinéa 1 de l'article L2323-17, après les mots « aux contrats de travail à
durée déterminée », sont insérés les mots « , aux contrats conclus avec une
entreprise de portage salarial ».

[...]


Article 63
----
À l'alinéa 1 de l'article L1615-2, après le mot « communes », est inséré le
caractère « , ».


Article 64
----
À l'alinéa 16 de l'article L3642-2, les mots « article L. 511-1 » sont remplacés
par les mots « article L. 511-2 ».

[...]
```
