# GitLegistique.jl -- Convert Git diffs of french law to legislative drafting
# By: Emmanuel Raviart <emmanuel.raviart@data.gouv.fr>
#
# Copyright (C) 2015 Etalab
# https://github.com/etalab/GitLegistique.jl
#
# The GitLegistique.jl package is licensed under the MIT "Expat" License.


module GitLegistique


using ArgParse
using Compat
using LibGit2
import LibGit2: text
using TextWrap


include("articles.jl")


function main()
  args = parse_command_line()

  repository = repo_discover(args["dir"])
  old_commit = revparse(repository, args["old"])
  new_commit = revparse(repository, args["new"])
  diff = LibGit2.diff(repository, old_commit, new_commit)
  articles = BuiltArticle[]
  for patch in patches(diff)
    delta = LibGit2.delta(patch)
    if delta.old_file.path == delta.new_file.path
      hunks = LibGit2.hunks(patch)
      if length(hunks) == 1
        # When there is only one hunk it may be the creation or deletion of an article.
        hunk = hunks[1]
        if hunk.old_start == 0 && hunk.old_lines == 0
          # Create article.
          println("Create article $(delta.new_file.path).")
          new_blob = lookup(repository, delta.new_file.oid)
          new_text = text(new_blob)
          push!(articles, CreateArticles(parse_article(new_text)))
          continue
        end
        if hunk.new_start == 0 && hunk.new_lines == 0
          # Delete article.
          println("Delete article $(delta.old_file.path).")
          old_blob = lookup(repository, delta.old_file.oid)
          old_text = text(old_blob)
          push!(articles, DeleteArticles(parse_article(old_text)))
          continue
        end
      end

      # Modify article.
      println("Modify article $(delta.new_file.path).")
      old_blob = lookup(repository, delta.old_file.oid)
      old_text = text(old_blob)
      old_article = parse_article(old_text)
      new_blob = lookup(repository, delta.new_file.oid)
      new_text = text(new_blob)
      new_article = parse_article(new_text)
      for hunk in hunks
        addition_encountered = false
        new_first_paragraph_index = 0
        new_last_paragraph_index = -1
        old_first_paragraph_index = 0
        old_last_paragraph_index = -1
        for line in lines(hunk)
          if line.line_origin == :addition
            addition_encountered = true
            new_last_paragraph_index = char_index_to_paragraph_index(new_article, line.content_offset + 1)
            if new_first_paragraph_index == 0
              new_first_paragraph_index = new_last_paragraph_index
            end
          elseif line.line_origin == :context
            if addition_encountered
              if old_first_paragraph_index == 0
                # Hunk contains no deletion.
                old_first_paragraph_index = line_index_to_paragraph_index(old_article, line.old_lineno - 1)
                old_last_paragraph_index = old_first_paragraph_index - 1
              end
            else
              # A first deletion may be on the next line.
              old_first_paragraph_index = line_index_to_paragraph_index(old_article, line.old_lineno + 1)
              old_last_paragraph_index = old_first_paragraph_index - 1
            end
          elseif line.line_origin == :deletion
            old_last_paragraph_index = char_index_to_paragraph_index(old_article, line.content_offset + 1)
            if old_first_paragraph_index == 0
              old_first_paragraph_index = old_last_paragraph_index
            end
          end
        end
        push!(articles, ModifyArticle(old_article, old_first_paragraph_index:old_last_paragraph_index,
          new_article, new_first_paragraph_index:new_last_paragraph_index))
      end
    else
      # Move/rename article.
      println("Rename article $(delta.old_file.path) to $(delta.new_file.path).")
      println("TODO")
      for hunk in hunks
        for line in lines(hunk)
          @show line.line_origin
          @show line.old_lineno
          @show line.new_lineno
          @show line.content_offset
          @show line.content
        end
      end
      stat = LibGit2.stat(patch)
      @show stat.adds
      @show stat.dels
    end
  end

  # Optimize articles.
  optimized_articles = BuiltArticle[]
  for (index, article) in enumerate(articles)
    if !isempty(optimized_articles)
      previous_article = optimized_articles[end]
      if isa(previous_article, DeleteArticles) && isa(article, DeleteArticles)
        append!(previous_article.deleted_articles, article.deleted_articles)
        continue
      end
    end
    push!(optimized_articles, article)
  end


  open(args["output_file"], "w") do output_file
    println(output_file, join(
      map(index_and_article -> text(index_and_article[2], index_and_article[1]), enumerate(optimized_articles)),
      "\n\n",
    ))
  end
end


function parse_command_line()
  arg_parse_settings = ArgParseSettings()
  @add_arg_table arg_parse_settings begin
    "--new", "-n"
      default = "HEAD"
      help = "target commit to compare to"
    "--old", "-o"
      default = "HEAD^"
      help = "source commit to compare from"
    "--verbose", "-v"
      action = :store_true
      help = "increase output verbosity"
    "dir"
      help = "path of Git repository containing French law"
      required = true
    "output_file"
      help = "path of generated file that will contain the diff in legal wordings"
      required = true
  end
  return parse_args(arg_parse_settings)
end


main()

end # module
