-module(blog_articles_controller, [Req]).
-compile(export_all).

index('GET', []) ->
	Articles = boss_db:find(article, []),
	{ok, [{articles, Articles}]}.

show('GET', [ArticleId]) ->
	Article = boss_db:find(ArticleId),
	{ok, [{article, Article}]}.

create('GET', []) -> ok;
create('POST', []) -> Article = article:new(id, Req:post_param("article_title"), Req:post_param("article_text")),
	case Article:save() of
		{ok, SavedArticle} -> {redirect, "/articles/show/"++SavedArticle:id()};
		{error, Errors} -> {ok, [{errors, Errors}, {article, Article}]}
	end.

delete('GET', [ArticleId]) ->
	boss_db:delete(ArticleId),
	{redirect, [{action, "index"}]}.

update('GET', [ArticleId]) -> Article = boss_db:find(ArticleId), {ok, [{article, Article}]};
update('POST', [ArticleId]) -> 
	Article = boss_db:find(ArticleId),
	EditedArticle = Article:set([{article_title, Req:post_param("article_title")},{article_text, Req:post_param("article_text")}]),
	EditedArticle:save(),
	{redirect, [{action, "index"}]}.

