/// Nodes for one learner and language. Event ids sit beside them so a replay
/// cannot apply the same evidence twice.
const String createKnowledgeNodes = '''
CREATE TABLE IF NOT EXISTS knowledge_nodes (
  user_id TEXT NOT NULL,
  language TEXT NOT NULL,
  node_key TEXT NOT NULL,
  payload TEXT NOT NULL,
  PRIMARY KEY (user_id, language, node_key)
)
''';

const String createKnowledgeGraphEvents = '''
CREATE TABLE IF NOT EXISTS knowledge_graph_events (
  client_event_id TEXT NOT NULL PRIMARY KEY,
  user_id TEXT NOT NULL,
  language TEXT NOT NULL,
  event_time INTEGER NOT NULL,
  payload TEXT NOT NULL
)
''';
