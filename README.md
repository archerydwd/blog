# Chicago Boss Blog Application

This is a tutorial for building a Chicago Boss blog application. If you get into trouble (like I did) try the mailing list or google it. For all the problems that I had, I have noted below the fixes I used.

I built this app with the Chicago Boss framework to be used as part of a series of applications that I will be 
performing benchmarking tests on.
See my Ruby on Rails version of this application here: https://github.com/archerydwd/ror_blog
The Flask version is here: https://github.com/archerydwd/flask_blog

I am going to be performing tests on this app using some load testing tools such as Gatling & Tsung. 

Once I have tested this application and the other verisons of it, I will publish the results, which can then be used as a benchmark for others when choosing a framework.

You can build this app using a framework of your choosing and then follow the testing mechanisms that I have described here: https://github.com/archerydwd/gatling-tests
Then compare your results against my benchmarks to get an indication of performance levels for your chosen framework.

=
###Installing Erlang and Chicago Boss

At the time of writing Erlang was at version: 17.4 and Chicago Boss at version: 0.8.14

**Install Erlang on osx using Homebrew:**

```
brew install erlang
```

**Installing Erlang on Linux:**

```
wget http://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
sudo dpkg -i erlang-solutions_1.0_all.deb
sudo apt-get update
sudo apt-get install erlang
```

**Install Chicago Boss:**

>Download the latest release from the Chicago Boss site: http://www.chicagoboss.org

*Compile it*

```
cd ChicagoBoss
make
```

If you get an error when doing the make command, about uuid then do the following:

>vim deps/boss_db/rebar.config

Find the line that contains git://gitorious.org/avtobiff/erlang-uuid.git and change it to:

```
https://gitorious.org/avtobiff/erlang-uuid.git
```

Now re-run the make command.

=
###Building the application

**Create the blog app**

```
cd ChicagoBoss
make app PROJECT=cb_blog
cd ../cb_blog
```

**Starting the development server**

To start the dev server:
```
./init-dev.sh
```

To stop the development server:
```
ctrl + c
```

=
###Create the article model

First we will require an article model, this file lives at: src/model/article.erl and you should 
insert the following into it:

```
-module(article, [Id, ArticleTitle, ArticleText]).
-compile(export_all).
```

I need to explain some things here. 

* The name of the file should be non-plural and in the -module part, the name should be the exact same (not including .erl extension of course).
* The attribute list is the [Id, ArticleTitle, ArticleText] part and this should always start with Id, which sets Chicago Boss to auto-generate the id. The names should all use camel case (even though in the database it will be article_title).
* -compile(export_all). is put in to the file to export all functions available in the article model.

=
###Create the article controller

The second thing we will do is create the controller associated with the article:

>touch src/controller/cb_blog_articles_controller.erl

>vim src/controller/cb_blog_articles_controller.erl

```
-module(cb_blog_articles_controller, [Req]).
-compile(export_all).   
index('GET', []) ->
    Articles = boss_db:find(article, []),
    {ok, [{articles, Articles}]}.
```

In the above code we are placing the name of the file in the module part. Please note the structure for the name of this file: APPNAME_MODELNAME_CONTROLLER.ERL In our case: cb_blog_articles_controller.erl. Please note that the modelname is plural here.

This controller 'gets' all the articles and provides them in a list to the index template that we will create next.
Please note the name of the actions in this controller have to be the same as the template they are calling.
Eg: index will give us the index.html template.

=
###Create the index template

In order to create the template for displaying all the articles, eg: an index page. We will do the following:

>mkdir src/view/articles

>touch src/view/articles/index.html

>vim src/view/articles/index.html

```
<html>
  <body>
    <h1>Listing articles</h1>
    <table>
      <tr>
        <th>Title</th>
        <th>Text</th>
      </tr>
      {% for article in articles %}
        <tr>
          <td>{{ article.article_title }}</td>
          <td>{{ article.article_text }}</td>
        </tr>
      {% endfor %}
    </table>
  <body>
</html>
```

The Chicago Boss templating uses Django's templating, Documentation can be found here: http://www.chicagoboss.org/api-view.html

=
###Associating comments with articles

We first must create the comment model: src/model/comment.erl

```
-module(comment, [Id, Commenter, Body, ArticleId]).
-compile(export_all).
-belongs_to(article).
```

The above says that each comment should belong to one article.

To follow this up we must add the following -has line to the src/model/article.erl file.

```
-module(article, [Id, ArticleTitle, ArticleText]).
-compile(export_All).

-has({comments, many}).
```

While the server is running, navigate to: http://localhost:8001/doc/article. You should see the comments/0 and comments/1 methods have been made available. Also navigate to: http://localhost:8001/doc/comment and you will see that the article/0 and article/1 methods have been made available. If these methods are not present, it means that you have made a mistake in one of the two above code boxes.

=
###Display individual articles

The first thing we will do is create a link to the individual articles in the src/view/articles/index.html file by just adding the following:

```
...
  <tr>
    <th>Title</th>
    <th>Text</th>
    <th colspan="1"></th>
  </tr>
  {% for article in articles %}
    <tr>
      <td>{{ article.article_title }}</td>
      <td>{{ article.article_text }}</td>
      <td><a href="/articles/show/{{ article.id }}">Show</a></td>
...
```

Then in the src/controller/cb_blog_articles_controller.erl file we need to add the following action:
```
...
show('GET', [ArticleId]) ->
   Article = boss_db:find(ArticleId),
   {ok, [{article, Article}]}.

```

We now need the: src/view/articles/show.html file:
```
<html>
  <body>
    <p>
      <strong>Title:</strong>
      {{ article.article_title }}
    </p>
    <p>
      <strong>Text:</strong>
      {{ article.article_text }}
    </p>
    <a href="/articles/index">Back</a>
  </body>
</html>
```

=
###Creating the articles

We now require a link to the create template from the index template: src/view/articles/index.html.

```
<html>
  <body>
    <h1>Listing articles</h1>
    <a href="{% url action="create" %}">New article</a>
    <table>
      <tr>
...
```

The action should be the same name used in your controller and the same name of the create template.

Now we will add the create template: 

>touch src/view/articles/create.html

>vim src/view/articles/create.html

```
<html>
  <body>
    <h1>New article</h1>
    {% if errors %}
      <ol>
        {% for error in errors %}
          <li><font color=red>{{ error }}</font>
        {% endfor %}
      </ol>
    {% endif %}
    
    <form method="post">
      <p>
        Title:<br>
        <input name="article_title" value="{{ article.article_title|default_if_none:'' }}"/>
      </p>
      <p>
        Text:<br>
        <textarea name="article_text" value="{{ article.article_text|default_if_none:'' }}"></textarea>
      </p>
      <p>
        <input type="submit" value="Create Article"/>
      </p>
    </form>
    <a href="{% url action="index" %}">Back</a>
  </body>
</html>
```

Finally, we can add the create action to: src/controller/cb_blog_articles_controller.erl

```
...
create('GET', []) -> ok;
create('POST', []) -> Article = article:new(id, Req:post_param("article_title"), Req:post_param("article_text")),
  case Article:save() of
    {ok, SavedArticle} -> {redirect, "/articles/show/"++SavedArticle:id()};
    {error, Errors} -> {ok, [{errors, Errors}, {article, Article}]}
  end.
```

The above create action has two versions, one for displaying the create page, and one for processing the 
posted data from the create page. It extracts the information by use of Req:post_param() and then creates a 
new article with the article:new() method and then saves it with the :save() method. 

If it successfully saves, then a redirect occurs to view that article. Otherwise, we get an error because the validation_tests in the model have failed. This is explained in the adding validation section.

The next step is to navigate to: http://localhost:8001/articles/create. You should see a form for creating the articles. Submit a few. You should see them displayed individually and they should display in the list of articles on the index page.

=
###Deleting an article

To delete an article we need to update the src/view/articles/index.html page to include a link to 
delete as per the following:

```
...
    <th>Text</th>
    
    <th colspan="2"></th>
  
  </tr>
  {% for article in articles %}
    <tr>
      <td>{{ article.article_title }}</td>
      <td>{{ article.article_text }}</td>
      <td><a href="/articles/show/{{ article.id }}">Show</a></td>
      
      <td><a href="/articles/delete/{{ article.id }}">Destroy</a></td>
      
    </tr>
  {% endfor %}
...
```

We now need to add the delete action to the controller: src/controller/cb_blog_articles_controller.erl

```
...
delete('GET', [ArticleId]) ->
  boss_db:delete(ArticleId),
  {redirect, [{action, "index"}]}.
```

=
###Adding validation

In the creating new articles section above. We saw the following code in the view:

```
{% if errors %}
  <ol>
    {% for error in errors %}
      <li><font color=red>{{ error }}</font>
       {% endfor %}
  </ol>
{% endif %}
```

The above code means if there are any reported errors, print them out. Where do these errors come from? Perhaps if we look at the controller:

```
create('GET', []) -> ok;
create('POST', []) -> Article = article:new(id, Req:post_param("article_title"), Req:post_param("article_text")),
  case Article:save() of
    {ok, SavedArticle} -> {redirect, "/articles/show/"++SavedArticle:id()};
    {error, Errors} -> {ok, [{errors, Errors}, {article, Article}]}
  end.
```

It can be seen that the create method either performs a redirect to display the saved article, or, if there was an error it pushes those errors back instead.

Now you are asking; where is the new article being checked for errors? 

The answer is; It's not currently being checked and now it needs to be added to the code to check for errors.

Adding validation that allows article titles to be longer than five characters can be done by adding the following code to the file: src/model/article.erl

```
-module(article, [Id, ArticleTitle, ArticleText]).
-compile(export_All).
-has({comments, many}).

validation_tests() ->
 [{fun() -> length(ArticleTitle) > 0 end, "Title can't be blank"},
  {fun() -> length(ArticleTitle) >= 5 end, "Title is too short (minimum is five characters)"}].
```

Now navigate to: http://localhost:8001/articles/create and enter a title that is less than five characters long. This will produce and display an error stating that the title is too short. This will also happen if you do not enter a title, but you will also get an error stating "Title can't be blank". What is happening here? The controller is trying to save an article, but as we have declared the validation_tests method in the model, they must execute before the article gets saved. If an error is found, the controller then passes these errors back to the view, which displays them.

=
###Updating articles

To add the update functionality we need to create a new file: src/view/articles/update.html and insert the following:

```
<html>
  <body>
    <form method="post">
      <p>
        Title:<br>
        <input name="article_title" value="{{ article.article_title }}"/>
      </p>
      <p>
        Text:<br>
        <textarea name="article_text">{{ article.article_text }}</textarea>
      </p>
      <p>
        <input type="submit" value="Update Article"/>
      </p>
    </form>
    <a href="{% url action="index" %}">Back</a>
  </body>
</html>
```

We now require a link to: src/view/articles/show.html so we can edit the article:

```
...
  {{ article.article_text }}
</p>
<a href="/articles/index">Back</a> | <
a href=”/articles/update/{{ article.id }}”>Edit</a>
```

Now we also need to add a link into the index: src/view/articles/index.html:

```
...
  <tr>
    <td>{{ article.article_title }}</td>
    <td>{{ article.article_text }}</td>
    <td><a href="/articles/show/{{ article.id }}">Show</a></td>
    <td><a href="/articles/update/{{ article.id }}">Edit</a></td>
    <td><a href="/articles/delete/{{ article.id }}">Destroy</a></td>
...
```

In the above we just added a link that calls the update action in the controller with the id of the article.
To get the update to work we need to add an update action to the controller: src/controller/cb_blog_articles_controller.erl:

```
...
update('GET', [ArticleId]) -> Article = boss_db:find(ArticleId), {ok, [{article, Article}]};
update('POST', [ArticleId]) ->
   Article = boss_db:find(ArticleId),
   EditedArticle = Article:set([{article_title, Req:post_param("article_title")},
                                {article_text,Req:post_param("article_text")}]),
   EditedArticle:save(),
   {redirect, [{action, "index"}]}.
```

This action has two clauses, one which gives back a page for that article, and one which accepts a form submission and updates the information of that article.

=
###Creating comments

*Issue:*

Due to the nature of chicago boss each action maps to a template. As the comments are created in the file: src/articles/show.html. When I create a comment, it automatically goes to the articles controller and gets the show action instead of going to the comments controller and getting the create method.

*Fix:*

The solution that I arrived at was to create a new route that mapped to the create action in the comments controller. This routing file is here: priv/blog.routes and it will be populated with a few examples. 
Change the first example under the formats section to the following:

```
% Formats:
{"/articles/comments/create", [{controller, "comments"}, {action, "create"}]}.
```

This change says that when the url: http://localhost:8001/articles/comments/create is entered, map it to the comments controller and the create action.

In order to display the comments and get this url input we need to edit: src/view/articles/show.html. As per the following:

```
<html>
  <body>
    <p>
      <strong>Title:</strong>
      {{ article.article_title }}
    </p>
    <p>
      <strong>Text:</strong>
      {{ article.article_text }}
    </p>
    <h2>Comments</h2>
    {% for comment in article.comments %}
      <p>
        <strong>Commenter:</strong>
        {{ comment.commenter }}
      </p>
      <p>
        <strong>Comment:</strong>
        {{ comment.body }}
      </p>
    {% endfor %}
    <h2>Add a comment:</h2>
    <form method="post" action="{% url action="comments/create" %}">
      <input type="hidden" name="id" value="{{ article.id }}" />
      <p>
        Commenter:<br>
        <input name="commenter" value="{{ comment.commenter|default_if_none:'' }}"/>
      </p>
      <p>
        Body:<br>
        <textarea name="body" value="{{ comment.body|default_if_none:'' }}"></textarea>
      </p>
      <p>
        <input type="submit" value="Create Comment"/>
      </p>
    </form>
    <a href="/articles/index">Back</a> | 
    <a href="/articles/update/{{ article.id }}”>Edit/a> 
  </body>
</html>
```

The part in the code above for displaying the comments makes use of the article.comments method which returns all comments that belong to the article that is being shown by this template. I then iterate and display them. The url action=”comments/create” attribute in the form head is responsible for getting the correct url.

Now we require a controller for the comments and an action called 'create':

>touch src/controller/cb_blog_comments_controller.erl

>vim src/controller/cb_blog_comments_controller.erl

```
-module(cb_blog_comments_controller, [Req]).
-compile(export_all).

create('POST', []) -> Comment = comment:new(id, Req:post_param("commenter"), Req:post_param("body"), Req:post_param("id")),
  Comment:save(),
  {redirect, [{controller, "articles"},{action, "show"},{article_id, Comment:article_id()}]}.
```

We should now be able to add comments and see them while viewing an individual article.

=
###Deleting comments

We need to edit the following to include a link for deleting comments.

>vim src/view/articles/show.html

```
...
    <strong>Comment:</strong>
    {{ comment.body }}
  </p>
  <a href="/comments/delete/{{ comment.id }}">Delete Comment</a>
{% endfor %}
...
```

The above form submits the comment’s id and article_id values. Which are needed to delete the comment and 
redirect back to show this article again.

We need to insert the following into: src/controller/cb_blog_comments_controller.erl:

```
...
delete('GET', [CommentId]) ->
  Comment = boss_db:find(CommentId),
  ArticleId = Comment:article_id(),
  boss_db:delete(CommentId),
  {redirect, [{controller, "article"},{action, "show"},{article_id, ArticleId}]}.
```

In this code, we are getting the comment by using the 'comment id'. Then we are getting the article id through the retrieved comment. We then delete the comment and redirect to the show action in the articles controller.

This is all that's involved in deleting comments. Now go to: http://localhost:8001/articles/index, select an article, add a few comments, and try to delete some of them.

=
###Routes

Edit the priv/blog.routes file and input:
```
% Front page
{"/", [{controller, "articles"}, {action, "index"}]}.
```
This makes http://localhost:8001/ redirect to http://localhost:8001/articles/index

=
###Getting Production Ready

First we need to compile the project and then we need to start it in production mode.

**Compile the application**

To compile the app, change directory to the app and run the following command:

```
./rebar compile
```

This should produce a .beam file in the directory ebin/

**Start in production mode**

To run in production mode, use the following command:

```
./init.sh start
```

=
###The End

Thanks for reading and hopefully you learned something. :)

Darren.
