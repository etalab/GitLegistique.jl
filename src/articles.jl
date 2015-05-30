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
      if article.new_paragraphs_range.start == article.new_paragraphs_range.stop
        # A single paragraph has been modified.
        # Detect whether paragraph modifications are subsequent.
        old_paragraph = article.old_article.text[article.old_article.paragraphs_chars_range[
          article.old_paragraphs_range.start]]
        new_paragraph = article.new_article.text[article.new_article.paragraphs_chars_range[
          article.new_paragraphs_range.start]]
        old_words = parse_words(old_paragraph)
        new_words = parse_words(new_paragraph)
        same_first_words_count = findfirst(collect(zip(old_words, new_words))) do old_word_and_new_word
          old_word, new_word = old_word_and_new_word
          return old_word != new_word
        end - 1
        same_last_words_count = findfirst(collect(zip(reverse(old_words), reverse(new_words)))) do old_word_and_new_word
          old_word, new_word = old_word_and_new_word
          return old_word != new_word
        end - 1
        if same_first_words_count + same_last_words_count > length(old_words) / 2
          # The two versions of the paragraph share a significant proportion of words.
          old_different_words = old_words[1 + same_first_words_count:end - same_last_words_count]
          new_different_words = new_words[1 + same_first_words_count:end - same_last_words_count]
          paragraph = string(
            "À l'alinéa ",
            article.old_paragraphs_range.start,
            " de l'article ",
            number(article.old_article),
            ",",
          )
          if isempty(old_different_words) || count(old_paragraph, strip(join(old_different_words))) > 1
            old_previous_word_index = same_first_words_count
            old_previous_words = Union(Char, String)[]
            while old_previous_word_index > 0
              unshift!(old_previous_words, old_words[old_previous_word_index])
              old_previous = strip(join(old_previous_words))
              if !isempty(old_previous) && count(old_paragraph, old_previous) <= 1
                break
              end
              old_previous_word_index -= 1
            end
            if old_previous_word_index == 0
              paragraph *= " au début,"
            end
            if !isempty(old_previous_words)
              paragraph *= string(
                " après",
                length(old_previous_words) > 1 ? " les mots " :
                  isa(old_previous_words[1], Char) ? " le caractère " : " le mot ",
                "« ",
                strip(join(old_previous_words)),
                " »,",
              )
            end
          end
          if isempty(old_different_words)
            @assert !isempty(new_different_words)
            paragraph *= string(
              length(new_different_words) > 1 ? " sont insérés les mots " :
                isa(new_different_words[1], Char) ? " est inséré le caractère " : " est inséré le mot ",
              "« ",
              strip(join(new_different_words)),
              " ».",
            )
          else
            paragraph *= string(
              length(old_different_words) > 1 ? " les mots " :
                isa(old_different_words[1], Char) ? " le caractère " : " le mot ",
              "« ",
              strip(join(old_different_words)),
              " »",
            )
            if isempty(new_different_words)
              paragraph *= length(old_different_words) > 1 ? " sont supprimés." : " est supprimé."
            else
              paragraph *= string(
                length(old_different_words) > 1 ? " sont remplacés " : " est remplacé ",
                "par",
                length(new_different_words) > 1 ? " les mots " :
                  isa(new_different_words[1], Char) ? " le caractère " : " le mot ",
                "« ",
                strip(join(new_different_words)),
                " ».",
              )
            end
          end
          push!(paragraphs, paragraph)
        else
          push!(paragraphs, string(
            "L'alinéa ",
            article.old_paragraphs_range.start,
            " de l'article ",
            number(article.old_article),
            " est remplacé par les dispositions suivantes :",
          ))
          append!(paragraphs,
            map(paragraph_index -> article.new_article.text[article.new_article.paragraphs_chars_range[paragraph_index]],
              article.new_paragraphs_range))
          paragraphs[2] = "« $(paragraphs[2])"
          paragraphs[end] = "$(paragraphs[end]) »"
        end
      else
        push!(paragraphs, string(
          "L'alinéa ",
          article.old_paragraphs_range.start,
          " de l'article ",
          number(article.old_article),
          " est remplacé par les dispositions suivantes :",
        ))
        append!(paragraphs,
          map(paragraph_index -> article.new_article.text[article.new_article.paragraphs_chars_range[paragraph_index]],
            article.new_paragraphs_range))
        paragraphs[2] = "« $(paragraphs[2])"
        paragraphs[end] = "$(paragraphs[end]) »"
      end
    else
      push!(paragraphs, string(
        "Les alinéas ",
        article.old_paragraphs_range.start,
        " à ",
        article.old_paragraphs_range.stop,
        " de l'article ",
        number(article.old_article),
        " sont remplacés par les dispositions suivantes :",
      ))
      append!(paragraphs,
        map(paragraph_index -> article.new_article.text[article.new_article.paragraphs_chars_range[paragraph_index]],
          article.new_paragraphs_range))
      paragraphs[2] = "« $(paragraphs[2])"
      paragraphs[end] = "$(paragraphs[end]) »"
    end
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


function count(s::String, sub::Char)
  c = -1
  index = 0
  while true
    c += 1
    index = search(s, sub, index + 1)
    if index == 0
      break
    end
  end
  return  c
end

function count(s::String, sub::String)
  c = -1
  index = 0
  while true
    c += 1
    range = search(s, sub, index + 1)
    if range.stop == -1
      break
    end
    index = range.start
  end
  return  c
end


function line_index_to_paragraph_index(article::ParsedArticle, line_index::Int)
  if line_index <= 0
    # When line index is -1 or 0, paragraph index is the same.
    return line_index
  end
  if line_index <= 2
    # When line index is 1 or 2, this is the article title, not a paragraph.
    return 0
  end
  for (paragraph_index, paragraph_lines_range) in enumerate(article.paragraphs_lines_range)
    # The "+ 1" below is because an empty line belongs to the previous paragraph.
    if paragraph_lines_range.start <= line_index <= paragraph_lines_range.stop + 1
      return paragraph_index
    end
  end
  error("Paragraph not found for line at index $line_index.")
end


number(article::ParsedArticle) = article.text[article.number_chars_range]


function parse_article(text::String)
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
    paragraph_lines_stop_index = paragraph_lines_start_index + count(
      text[paragraph_chars_start_index:paragraph_chars_stop_index], '\n')
    push!(article.paragraphs_chars_range, paragraph_chars_start_index:paragraph_chars_stop_index)
    push!(article.paragraphs_lines_range, paragraph_lines_start_index:paragraph_lines_stop_index)
    paragraph_chars_start_index = paragraph_chars_stop_index + 3
    paragraph_lines_start_index = paragraph_lines_stop_index + 2
  end
  return article
end


function parse_words(paragraph::String)
  # Separate words, spaces & punctuation.
  fragments = Union(Char, String)[]
  word = ""
  for c in paragraph
    if isspace(c)
      if !isempty(word)
        push!(fragments, word)
        word = ""
      end
      if isempty(fragments) || fragments[end] != ' '
        push!(fragments, ' ')
      end
    elseif ispunct(c)
      if !isempty(word)
        push!(fragments, word)
        word = ""
      end
      push!(fragments, c)
    else
      word *= string(c)
    end
  end
  if !isempty(word)
    push!(fragments, word)
  end
  return fragments
end


text(article::BuiltArticle, index::Int) = string(
  "Article $(index)\n",
  "----\n",
  body(article),
)
