import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../analysis/bloc/analysis_bloc.dart';
import '../../analysis/view/analysis_tab.dart';
import '../../chat/bloc/chat_bloc.dart';
import '../../chat/bloc/chat_event.dart';
import '../../chat/view/chat_tab.dart';
import '../../embedding/bloc/embedding_bloc.dart';
import '../../embedding/bloc/embedding_event.dart';
import '../../embedding/view/embedding_tab.dart';
import '../../generation/bloc/generation_bloc.dart';
import '../../generation/view/generation_tab.dart';
import '../../rag/bloc/rag_bloc.dart';
import '../../rag/bloc/rag_event.dart';
import '../../rag/view/rag_tab.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GenerationBloc()),
        BlocProvider(create: (_) => AnalysisBloc()),
        BlocProvider(
          create: (_) => EmbeddingBloc()..add(const EmbeddingCheckRequested()),
        ),
        BlocProvider(create: (_) => RagBloc()..add(const RagCheckRequested())),
        BlocProvider(create: (_) => ChatBloc()..add(const ChatStarted())),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Local LLM'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.edit_document),
                child: Text(
                  'Generation',
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
              Tab(
                icon: Icon(Icons.analytics_outlined),
                child: Text(
                  'Analysis',
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
              Tab(
                icon: Icon(Icons.scatter_plot_outlined),
                child: Text(
                  'Embedding',
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
              Tab(
                icon: Icon(Icons.travel_explore_outlined),
                child: Text(
                  'RAG',
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
              Tab(
                icon: Icon(Icons.chat_bubble_outline),
                child: Text(
                  'Chat',
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            GenerationTab(),
            AnalysisTab(),
            EmbeddingTab(),
            RagTab(),
            ChatTab(),
          ],
        ),
      ),
    );
  }
}
