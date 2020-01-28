import 'dart:async';

import 'package:ant_icons/ant_icons.dart';
import 'package:corona_flutter/core/api.dart';
import 'package:corona_flutter/core/news.dart';
import 'package:corona_flutter/model/model.dart';
import 'package:corona_flutter/widgets/items/news_snippet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

class NewsPage extends StatefulWidget {
  final NewsService newsService;

  const NewsPage({
    Key key,
    this.newsService,
  }) : super(key: key);

  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  ScrollController newsFeedController;
  ScrollController appBarController;
  int page = 0;
  NewsFeedType feedType = NewsFeedType.trending;

  @override
  void initState() {
    super.initState();

    appBarController = ScrollController();
    newsFeedController = ScrollController()
      ..addListener(() {
        appBarController.jumpTo(newsFeedController.offset);
        if (newsFeedController.offset >=
                newsFeedController.position.maxScrollExtent &&
            !newsFeedController.position.outOfRange) {
          setState(() {
            page++;
            loadArticles();
          });
        }
      });

    widget.newsService.addListener(() {
      setState(() {});
    });

    loadArticles();
  }

  @override
  void dispose() {
    newsFeedController.dispose();
    super.dispose();
  }

  loadArticles() {
    widget.newsService.fetch(offset: page * 10, feedType: feedType);
  }

  Future<void> handleRefresh() async {
    setState(() {
      widget.newsService.clear();
      page = 0;
      loadArticles();
    });
    return;
  }

  void openArticle(String url) async {
    try {
      await launch(
        url,
        option: CustomTabsOption(
          toolbarColor: Theme.of(context).primaryColor,
          enableDefaultShare: true,
          enableUrlBarHiding: true,
          showPageTitle: true,
          animation: CustomTabsAnimation.slideIn(),
          extraCustomTabs: <String>[
            'org.mozilla.firefox',
            'com.microsoft.emmx',
          ],
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      controller: appBarController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            title: Text(
              '${feedType == NewsFeedType.latest ? 'Latest' : 'Trending'} News',
              style: TextStyle(
                fontSize: 28.0,
                color: Colors.black.withOpacity(0.75),
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: <Widget>[
              PopupMenuButton<NewsFeedType>(
                offset: Offset(0.0, 8.0),
                icon: Icon(
                  AntIcons.sliders_outline,
                  color: Colors.black.withOpacity(0.75),
                ),
                onSelected: (type) {
                  if (type == feedType) return;

                  setState(() {
                    page = 0;
                    widget.newsService.clear();
                    feedType = type;
                    loadArticles();
                  });
                },
                itemBuilder: (context) => <PopupMenuEntry<NewsFeedType>>[
                  PopupMenuItem<NewsFeedType>(
                    value: NewsFeedType.trending,
                    child: Text('Trending'),
                  ),
                  PopupMenuItem<NewsFeedType>(
                    value: NewsFeedType.latest,
                    child: Text('Latest'),
                  )
                ],
              ),
            ],
            elevation: 0.0,
            backgroundColor: Colors.white24,
          ),
        ];
      },
      body: RefreshIndicator(
        onRefresh: handleRefresh,
        child: NewsFeed(
          key: PageStorageKey('newsFeed'),
          news: widget.newsService.news,
          controller: newsFeedController,
          onTapNews: openArticle,
          state: widget.newsService.state,
        ),
      ),
    );
  }
}

class NewsFeed extends StatelessWidget {
  final List<News> news;
  final Function(String) onTapNews;
  final ScrollController controller;
  final NewsFeedState state;

  NewsFeed({
    Key key,
    this.news,
    this.onTapNews,
    this.controller,
    this.state,
  }) : super(key: key);

  bool get isLoading => state == NewsFeedState.loading;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: isLoading ? news.length + 1 : news.length,
      physics: const AlwaysScrollableScrollPhysics(),
      controller: controller,
      separatorBuilder: (context, index) {
        if (isLoading && index >= news.length - 1) {
          return Container();
        }

        return SizedBox(
          height: 12.0,
          child: Container(color: Colors.grey[200]),
        );
      },
      itemBuilder: (context, index) {
        if (isLoading && index == news.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return NewsSnippet(
          title: news[index].title,
          timestamp: news[index].publishedAt ?? '',
          url: news[index].url,
          imgUrl: news[index].urlToImage ?? '',
          onTap: onTapNews,
        );
      },
    );
  }
}
