-module(article, [Id, ArticleTitle, ArticleText]).
-compile(export_all).
-has({comments, many}).

validation_tests() ->
	[{fun() -> length(ArticleTitle) > 0 end, "Title can't be blank"},
		{fun() -> length(ArticleTitle) >= 5 end, "Title is too short (minimum is 5 characters)"}].

