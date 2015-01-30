-module(blog_comment_controller, [Req]).
-compile(export_all).

create('POST', []) -> Comment = comment:new(id, Req:post_param("commenter"), Req:post_param("body"), Req:post_param("id")),
	Comment:save(),
	{redirect, [{controller, "article"},{action, "show"},{article_id, Comment:article_id()}]}.

delete('GET', [CommentId]) ->
	Comment = boss_db:find(CommentId),
	ArticleId = Comment:article_id(),
	boss_db:delete(CommentId),
	{redirect, [{controller, "article"},{action, "show"},{article_id, ArticleId}]}.
