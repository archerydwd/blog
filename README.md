# Chicago Boss Blog Application

Please note this is not a tutorial, I have wrote it in that style so you can follow along. If you get into troble (like I did) try the mailing list or just google it. You will find that you will actually learn more from researching it and getting into tight spots. ;) 

I built this app with the Chicago Boss framework to be used as part of a series of applications that I will be 
performing tests on. This is a Chicago Boss version of the Ruby on Rails blog application: https://github.com/archerydwd/rails-blog.

I am going to be performing tests on this app using some load testing tools such as Tsung and J-Meter. 

Once I have tested this application and the Ruby on Rails verison of it, I will publish the results, which can then be used as a benchmark for others to use when trying to choose a framework.

You can build this app using a framework of your choosing and then follow the testing mechanisms that I will describe and then compare the results against my benchmark to get an indication of performance levels of your chosen framework.

==
###Installing Erlang and Chicago Boss
==

At the time of writing Erlang was at version: 17.4 and Chicago Boss at version: 0.8.12

**Install Erlang on osx using Homebrew:**
```
brew install erlang
```
**Installing Erlang on Linux:**
```
sudo apt-get update
sudo apt-get erlang
```
**Install Chicago Boss:**

>Download the latest release from the Chicago Boss site: http://www.chicagoboss.org

*Compile it*
```
cd ChicagoBoss
make
```

**Create the blog app**
```
make app PROJECT=blog
cd ../blog
```


###Building the application

==
**Starting the development server**
==

To start the dev server:
```
./init-dev.sh
```

To stop the development server:
```
ctrl + c
```

==
**Create the article model**
==

First we will need an article model, this file lives at: src/model/article.erl and you should 
insert the following into it:
```
-module(article, [Id, ArticleTitle, ArticleText]).
-compile(export_all).
```
We need to explain some things here. 

* The name of the file should be non-plural and in the -module part, the name should be the exact same (not including .erl extension of course)
* The attribute list is the [Id, ArticleTitle, ArticleText] part and this should always start with Id, which sets Chicago Boss to auto generate the id. The names should all use camel case (even though in the database it will be article_title).
* -compile(export_all) is put in to export all functions available to the article model.

==
**Create the article controller**
==

The second thing we will need to do is to create the controller associated with the article. This file will live at: 
src/controller/blog_articles_controller.erl
```
-module(blog_articles_controller, [Req]).
-compile(export_all).   
index('GET', []) ->
    Articles = boss_db:find(article, []),
    {ok, [{articles, Articles}]}.
```
Again in the above we are placing the name of the file in the module part. Please note the structure for the name of this 
file is: APPNAME_MODELNAME_CONTROLLER.ERL so for our case, it should be: blog_articles_controller.erl. 
Also note that the modelname is plural here.

This controller gets all the articles and provides them in a list to the index template that we will now create.
Please note the name of the actions in this controller have to be the same as the template they are calling.
Eg: index will get us the index.html template.

==
**Display all articles template**
==

The next thing we will need to do is create the template for displaying the articles, eg: an index page. This file 
lives at: src/view/articles/index.html you will need to create the directory src/view/articles, please note it is also plural.
>mkdir src/view/articles
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

==
**Associating comments with articles**
==

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

While the server is running, navigate to: http://localhost:8001/doc/article. You should see the comments/0 and comments/1 methods have been made available. Also navigate to: http://localhost:8001/doc/comment and you will see that the article/0 and article/1 methods have been made available. If these methods are not here, it means that you have made a mistake in one of the above two code boxes.

**Display individual articles**

The first thing we will do is create a link to the individual articles in the src/view/articles/index.html file, by just adding the following:
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

Then in the src/controller/blog_articles_controller.erl file we need to add the following action:
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

Now we need a way to create new articles so we can then create new comments on them.

**Creating the articles**

We need to add a link to the create template from the index template (src/view/articles/index.html)
```
<html>
  <body>
    <h1>Listing articles</h1>
    <a href="{% url action="create" %}">New article</a>
    <table>
      <tr>
...
```

The action should be the same name that you have in your controller and the same name of the create template.

Now we will add the create template to: src/view/articles/create.html
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

Finally we will add the create action to: src/controller/blog_articles_controller.erl
```
...
create('GET', []) -> ok;
create('POST', []) -> Article = article:new(id, Req:post_param("article_title"), Req:post_param("article_text")),
  case Article:save() of
    {ok, SavedArticle} -> {redirect, "/articles/show/"++SavedArticle:id()};
    {error, Errors} -> {ok, [{errors, Errors}, {article, Article}]}
  end.
```

The above create action has two versions, one is for displaying the create page, and one is for processing the 
posted data from the create page. It extracts the information by use of Req:post_param() and then creates a 
new article with the article:new() method and then saves it with the :save() method. 
If it saves ok, then a redirect occurs to view that article. Otherwise we get an error because the validation_tests in the model have failed, again this is explained in the adding validation section.

Now navigate to: http://localhost:8001/articles/create. You should see a form for creating the articles. Submit a few. You should see them displayed individually and they should display in the list of articles on the index page.

**Deleting an article**

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

We now need to add the delete action to the controller: src/controller/blog_articles_controller.erl
```
...
delete('GET', [ArticleId]) ->
  boss_db:delete(ArticleId),
  {redirect, [{action, "index"}]}.
```

**Adding validation**

In the creating new articles section above we saw the following code in the view:
```
{% if errors %}
  <ol>
    {% for error in errors %}
      <li><font color=red>{{ error }}</font>
       {% endfor %}
  </ol>
{% endif %}
```
This code basically means if there are any reported errors, print them out. So where did these errors come from? Well if we look at the controller:
```
create('GET', []) -> ok;
create('POST', []) -> Article = article:new(id, Req:post_param("article_title"), Req:post_param("article_text")),
  case Article:save() of
    {ok, SavedArticle} -> {redirect, "/articles/show/"++SavedArticle:id()};
    {error, Errors} -> {ok, [{errors, Errors}, {article, Article}]}
  end.
```
We see the create method either performs a redirect to display the saved article, or if there was an error it pushes those errors back instead. 

So now you are asking: Where is the new article being checked for errors? 

The answer to this is: It is not currently being checked and we now need to add the code to check for errors.

To add validation that only allows article titles to be longer than five characters, in: src/model/article.erl add the following code:
```
-module(article, [Id, ArticleTitle, ArticleText]).
-compile(export_All).
-has({comments, many}).

validation_tests() ->
 [{fun() -> length(ArticleTitle) > 0 end, "Title can't be blank"},
  {fun() -> length(ArticleTitle) >= 5 end, "Title is too short (minimum is five characters)"}].
```
Then if you navigate to: http://localhost:8001/article/create and enter a title that is less than five characters long, it will produce and display an error stating that the title is too short. This will also happen if you don’t enter a title, but you will also get an error stating "Title can't be blank". So what is happening here? The controller is trying to save an article, but because we have declared this validation_tests method in the model, they must execute first. If an error is found, the controller then passes these errors back to the view, which then displays them.

**Updating articles**

To add the update functionality we need to create a new file: src/view/article/update.html and insert the following:
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
We need to add a link to: src/view/articles/show.html so we can edit the article:
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
Now to get the update to work we need to add an update action to the controller: src/controller/blog_articles_controller.erl:
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

**Creating comments**

*Issue:*

With this I had a problem. Due to the nature of chicago boss each action maps to a view, and due to the comments 
being created in: src/articles/show.html. When I submit the form, it automatically goes to the 
controller: src/controller/blog_articles_controller.erl and hits the show action for articles instead of going to the comments controller: src/controller/blog_comments_controller.erl and hitting the create method there.

*Fix:*

The solution that I arrived at was to create a new route that mapped to the create action in the 
comments controller. This routing file lives at: priv/blog.routes and it will be populated with a few examples. 
If you change the first example under the formats section to the following:
```
% Formats:
{"/articles/comments/create", [{controller, "comments"}, {action, "create"}]}.
```
This says that when the url: http://localhost:8001/article/comments/create is entered, map it to the controller: comments and the action: create.

In order to display the comments and get this url input we need to edit: src/view/article/show.html. As per the following:
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

The part for displaying the comments makes use of the article.comments method which returns all comments that belong to this article. We can then loop through them and display them. The part that is responsible for getting the correct url is the url action=”comments/create” attribute in the form head.

Now we need a controller for the comment and an action called 'create', this file lives at: src/controller/blog_comments_controller.erl, insert the following into it:
```
-module(blog_comments_controller, [Req]).
-compile(export_all).

create('POST', []) -> Comment = comment:new(id, Req:post_param("commenter"), Req:post_param("body"), Req:post_param("id")),
  Comment:save(),
  {redirect, [{controller, "articles"},{action, "show"},{article_id, Comment:article_id()}]}.
```
We should now be able to add comments and see them while viewing an individual article.

**Deleting comments**

We need to edit: src/view/articles/show.html to include a link for deleting comments:
```
...
    <strong>Comment:</strong>
    {{ comment.body }}
  </p>
  <a href="/comment/delete/{{ comment.id }}">Delete Comment</a>
{% endfor %}
...
```

The above form submits the comment’s id and article_id values. Which are needed to delete the comment and 
redirect back to show this article again.

We need to insert the following into: src/controller/blog_comments_controller.erl:
```
...
delete('GET', [CommentId]) ->
  Comment = boss_db:find(CommentId),
  ArticleId = Comment:article_id(),
  boss_db:delete(CommentId),
  {redirect, [
    {controller, "article"},
    {action, "show"},
    {article_id, ArticleId}
  ]}.
```
In this, we are getting the comment by using the comment id. Then we are getting the article id from the 
comment, deleting the comment and then redirecting to the show action. 

So that's all there is to deleting comments, go to: http://localhost:8001/articles/index and select an article, add a few comments and then try to delete some of them.

**Routes**

Edit the priv/blog.routes file and input:
```
% Front page
{"/", [{controller, "articles"}, {action, "index"}]}.
```
This makes http://localhost:8001/ redirect to http://localhost:8001/articles/index

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

###The End

That's all there is to it. This was my first self made (without a tutorial) application with Chicago Boss, so if you notice any problems or enhancements, please drop me a message.

Thanks for reading and hopefully you learned something. :)

Darren.
