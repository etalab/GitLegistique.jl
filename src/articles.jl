# GitLegistique.jl -- Convert Git diffs of french law to legislative drafting
# By: Emmanuel Raviart <emmanuel.raviart@data.gouv.fr>
#
# Copyright (C) 2015 Etalab
# https://github.com/etalab/GitLegistique.jl
#
# The GitLegistique.jl package is licensed under the MIT "Expat" License.


abstract Article
abstract BuiltArticle <: Article


type ParsedArticle <: Article
  text::String
  number_chars_range::Range
  paragraphs_chars_range::Vector{Range}
  paragraphs_lines_range::Vector{Range}
end


type CreateArticles <: BuiltArticle
  created_articles::Array{ParsedArticle}
end

CreateArticles(created_article::ParsedArticle) = CreateArticles(ParsedArticle[created_article])


type DeleteArticles <: BuiltArticle
  deleted_articles::Array{ParsedArticle}
end

DeleteArticles(deleted_article::ParsedArticle) = DeleteArticles(ParsedArticle[deleted_article])


type ModifyArticle <: BuiltArticle
  old_article::ParsedArticle
  old_paragraphs_range::Range
  new_article::ParsedArticle
  new_paragraphs_range::Range
end


function body(article::CreateArticles)
  @assert length(article.created_articles) == 1
  created_article = article.created_articles[1]
  created_article_number = number(created_article)
  paragraphs = String[
    "Il est inséré un article $created_article_number ainsi rédigé :",
  ]
  append!(paragraphs,
    map(paragraph_range -> created_article.text[paragraph_range], created_article.paragraphs_chars_range))
  paragraphs[2] = "« Art. $created_article_number – $(paragraphs[2])"
  paragraphs[end] = "$(paragraphs[end]) »"
  return string(join(map(paragraph -> wrap(rstrip(paragraph); width = 80), paragraphs), "\n\n"), '\n')
end

function body(article::DeleteArticles)
  if length(article.deleted_articles) == 1
    return wrap("L'article $(number(article.deleted_articles[1])) est abrogé.\n"; width = 80)
  else
    return wrap("Les articles $(join(map(number, article.deleted_articles), ", ", " et ")) sont abrogés.\n"; width = 80)
  end
end

function body(article::ModifyArticle)
  paragraphs = String[]
  if article.old_paragraphs_range.start > article.old_paragraphs_range.stop
    # Insert paragraphs.
    if article.old_paragraphs_range.start <= 1
      push!(paragraphs, string(
        "Il est inséré avant l'alinéa ",
        article.old_paragraphs_range.start,
        " de l'article ",
        number(article.old_article),
        " les disposition suivantes :",
      ))
    else
      push!(paragraphs, string(
        "Il est inséré après l'alinéa ",
        article.old_paragraphs_range.stop,
        " de l'article ",
        number(article.old_article),
        " les disposition suivantes :",
      ))
    end
    append!(paragraphs,
      map(paragraph_index -> article.new_article.text[article.new_article.paragraphs_chars_range[paragraph_index]],
        article.new_paragraphs_range))
    paragraphs[2] = "« $(paragraphs[2])"
    paragraphs[end] = "$(paragraphs[end]) »"
  elseif article.new_paragraphs_range.start > article.new_paragraphs_range.stop
    # Delete paragraphs.
    if article.old_paragraphs_range.start == article.old_paragraphs_range.stop
      push!(paragraphs, string(
        "L'alinéa ",
        article.old_paragraphs_range.start,
        " de l'article ",
        number(article.old_article),
        " est supprimé.",
      ))
    else
      push!(paragraphs, string(
        "Les alinéas ",
        article.old_paragraphs_range.start,
        " à ",
        article.old_paragraphs_range.stop,
        " de l'article ",
        number(article.old_article),
        " sont supprimés.",
      ))
    end
  else
    # Modify paragraphs.
    if article.old_paragraphs_range.start == article.old_paragraphs_range.stop
      push!(paragraphs, string(
        "L'alinéa ",
        article.old_paragraphs_range.start,
        " de l'article ",
        number(article.old_article),
        " est remplacé par les disposition suivantes :",
      ))
    else
      push!(paragraphs, string(
        "Les alinéas ",
        article.old_paragraphs_range.start,
        " à ",
        article.old_paragraphs_range.stop,
        " de l'article ",
        number(article.old_article),
        " sont remplacés par les disposition suivantes :",
      ))
    end
    append!(paragraphs,
      map(paragraph_index -> article.new_article.text[article.new_article.paragraphs_chars_range[paragraph_index]],
        article.new_paragraphs_range))
    paragraphs[2] = "« $(paragraphs[2])"
    paragraphs[end] = "$(paragraphs[end]) »"
  end
  return string(join(map(paragraph -> wrap(rstrip(paragraph); width = 80), paragraphs), "\n\n"), '\n')
end

body(article::ParsedArticle) = article.text[article.paragraphs_chars_range[1].start:end]


function char_index_to_paragraph_index(article::ParsedArticle, char_index::Int)
  if char_index <= 0
    # When character index is -1 or 0, paragraph index is the same.
    return char_index
  end
  if article.text[char_index] == '\n' && article.text[char_index - 1] == '\n'
    # An empty line belongs to the previous paragraph.
    char_index -= 2
  end
  for (paragraph_index, paragraph_chars_range) in enumerate(article.paragraphs_chars_range)
    if paragraph_chars_range.start <= char_index <= paragraph_chars_range.stop
      return paragraph_index
    end
  end
  error("Paragraph not found for character at index $char_index.")
end


function line_index_to_paragraph_index(article::ParsedArticle, line_index::Int)
  if line_index <= 0
    # When line index is -1 or 0, paragraph index is the same.
    return line_index
  end
  for (paragraph_index, paragraph_lines_range) in enumerate(article.paragraphs_lines_range)
    if paragraph_lines_range.start <= line_index <= paragraph_lines_range.stop
      return paragraph_index
    end
  end
  error("Paragraph not found for line at index $line_index.")
end


number(article::ParsedArticle) = article.text[article.number_chars_range]


function parse_article(text)
  line1, line2, body = split(text, "\n", 3)
  @assert startswith(line1, "Article ")
  number_str = line1[sizeof("Article ") + 1:end]
  @assert line2 == "----"
  article = ParsedArticle(text, sizeof("Article ") + 1:sizeof(line1), Range[], Range[])
  paragraph_chars_start_index = 1 + sizeof(line1) + 1 + sizeof(line2) + 1
  paragraph_lines_start_index = 3
  while paragraph_chars_start_index <= sizeof(text)
    paragraph_separator_range = search(text, "\n\n", paragraph_chars_start_index)
    paragraph_chars_stop_index = paragraph_separator_range.start > 0 ?
      paragraph_separator_range.start - 1 :
      sizeof(rstrip(text))
    paragraph_lines_stop_index = paragraph_lines_start_index + count(char -> char == '\n',
      text[paragraph_chars_start_index:paragraph_chars_stop_index])
    push!(article.paragraphs_chars_range, paragraph_chars_start_index:paragraph_chars_stop_index)
    push!(article.paragraphs_lines_range, paragraph_lines_start_index:paragraph_lines_stop_index)
    paragraph_chars_start_index = paragraph_chars_stop_index + 3
    paragraph_lines_start_index = paragraph_lines_stop_index + 2
  end
  return article
end


text(article::BuiltArticle, index::Int) = string(
  "Article $(index)\n",
  "----\n",
  body(article),
)
