import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:urbanmatch_assignment1/repo.dart';

// @dart=2.9
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
      ),
      home: Home(),
    );
  }
}

Future<List<Repo>> fetchRepos() async {
  final response = await http
      .get(Uri.parse('https://api.github.com/users/freeCodeCamp/repos'));

  if (response.statusCode == 200) {
    final data = json.decode(response.body) as List<dynamic>;
    return data
        .map((json) => Repo.fromJson(json))
        .toList(); // More concise conversion
  } else {
    throw Exception('Failed to fetch repos!');
  }
}

class Commit {
  final String message;
  final String sha; // Commit SHA identifier
  final String authorName; // Author name
  final String authorEmail; // Author email

  Commit({
    required this.message,
    this.sha = '',
    this.authorName = '',
    this.authorEmail = '',
  });

  factory Commit.fromJson(Map<String, dynamic> json) {
    return Commit(
      message: json['commit']['message'],
      sha: json['sha'], // Assuming SHA is present in the response
      authorName: json['commit']['author']
          ['name'], // Assuming author info is present
      authorEmail: json['commit']['author']
          ['email'], // Assuming email is present
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<List<Repo>> futureRepo;

  @override
  void initState() {
    super.initState();
    futureRepo = fetchRepos();
  }

  Future<Commit?> fetchLastCommit(String repoUrl) async {
    final response = await http.get(Uri.parse('$repoUrl/commits'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return Commit.fromJson(data);
    } else {
      return null; // Return null for failed requests
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GitHub API'),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: FutureBuilder<List<Repo>>(
          future: futureRepo,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final repos = snapshot.data!;

              return ListView.builder(
                itemCount: repos.length,
                itemBuilder: (context, index) {
                  final repo = repos[index];
                  return FutureBuilder<Commit?>(
                    future: fetchLastCommit(repo.htmlUrl),
                    builder: (context, commitSnapshot) {
                      if (commitSnapshot.hasData) {
                        final commit = commitSnapshot.data!;
                        return Card(
                          color: Colors.lightBlueAccent,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(repo.name, style: TextStyle(fontSize: 14.0)),
                              Text(repo.description),
                              // Handle potential null description
                              Text(repo.htmlUrl),
                              Text(repo.stargazersCount.toString()),
                              Text(
                                "Last Commit: ${commit.message}",
                                style: TextStyle(fontSize: 12.0),
                              ),
                            ],
                          ),
                        );
                      } else if (commitSnapshot.hasError) {
                        return Card(
                          color: Colors.lightBlueAccent,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(repo.name, style: TextStyle(fontSize: 14.0)),
                              Text(repo.description),
                              // Handle potential null description
                              Text(repo.htmlUrl),
                              Text(repo.stargazersCount.toString()),
                              // Display error message for failed commit fetch
                              Text(
                                "Error fetching last commit!",
                                style: TextStyle(
                                    fontSize: 12.0, color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Display a loading indicator while fetching the last commit
                        return Card(
                          color: Colors.lightBlueAccent,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(repo.name, style: TextStyle(fontSize: 14.0)),
                              Text(repo.description),
                              // Handle potential null description
                              Text(repo.htmlUrl),
                              Text(repo.stargazersCount.toString()),
                              CircularProgressIndicator(),
                              // Display loading indicator
                            ],
                          ),
                        );
                      }
                    },
                  );
                },
              );
            } else if (snapshot.hasError) {
              // Handle errors for the main future
              return Center(
                child: Text('Error fetching repos!'),
              );
            } else {
              // Display a loading indicator while fetching repos
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }
}
