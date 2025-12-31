# Claude Flow Configuration v0.1.0

MCP tools and skills reference.

## Contents
1. Available Tools - Claude Flow, NixOS MCP, Context7, Skills
2. When to Use - triggers for each tool category
3. How to Use - concrete examples
4. References - documentation links

## Available Tools

MCP tools coordinate, Claude Code executes.

### Claude Flow (`mcp__claude-flow__*`)

Swarm:
- `swarm_init(topology, strategy?, maxAgents?)` - Initialize swarm
- `swarm_status(swarmId?)` - Check swarm health
- `swarm_monitor(swarmId?, interval?)` - Real-time monitoring
- `swarm_scale(swarmId?, targetSize)` - Scale agent count
- `swarm_destroy(swarmId)` - Terminate swarm
- `agent_spawn(type, name?, capabilities?, swarmId?)` - Create agent
- `agents_spawn_parallel(agents, maxConcurrency?, batchSize?)` - Batch spawn
- `agent_list(swarmId?)` - View active agents
- `agent_metrics(agentId?)` - Agent performance data
- `task_orchestrate(task, strategy?, priority?, dependencies?)` - Coordinate tasks
- `task_status(taskId)` - Check task progress
- `task_results(taskId)` - Get task results
- `topology_optimize(swarmId?)` - Auto-optimize topology
- `load_balance(swarmId?, tasks?)` - Distribute tasks
- `coordination_sync(swarmId?)` - Sync agent coordination

Memory:
- `memory_usage(action, key?, value?, namespace?, ttl?)` - Store/retrieve data
- `memory_search(pattern, namespace?, limit?)` - Find by pattern
- `memory_persist(sessionId?)` - Cross-session persistence
- `memory_namespace(namespace, action)` - Namespace management
- `memory_backup(path?)` - Backup stores
- `memory_restore(backupPath)` - Restore from backup
- `memory_compress(namespace?)` - Compress data
- `memory_sync(target)` - Sync across instances
- `memory_analytics(timeframe?)` - Usage analysis
- `cache_manage(action, key?)` - Manage cache
- `state_snapshot(name?)` - Create snapshot
- `context_restore(snapshotId)` - Restore context

Neural:
- `neural_status(modelId?)` - Neural network status
- `neural_train(pattern_type, training_data, epochs?)` - Train patterns
- `neural_patterns(action, operation?, outcome?, metadata?)` - Analyze patterns
- `neural_predict(modelId, input)` - Make predictions
- `neural_compress(modelId, ratio?)` - Compress models
- `neural_explain(modelId, prediction)` - AI explainability
- `model_load(modelPath)` - Load models
- `model_save(modelId, path)` - Save models
- `inference_run(modelId, data)` - Run inference
- `pattern_recognize(data, patterns?)` - Pattern recognition
- `cognitive_analyze(behavior)` - Behavior analysis
- `learning_adapt(experience)` - Adaptive learning
- `ensemble_create(models, strategy?)` - Create ensembles
- `transfer_learn(sourceModel, targetDomain)` - Transfer learning
- `wasm_optimize(operation?)` - WASM SIMD optimization

GitHub:
- `github_repo_analyze(repo, analysis_type?)` - Repository analysis
- `github_pr_manage(repo, action, pr_number?)` - PR management
- `github_issue_track(repo, action)` - Issue tracking
- `github_release_coord(repo, version)` - Release coordination
- `github_workflow_auto(repo, workflow)` - Workflow automation
- `github_code_review(repo, pr)` - Code review
- `github_sync_coord(repos)` - Multi-repo sync
- `github_metrics(repo)` - Repository metrics

DAA (Decentralized Autonomous Agents):
- `daa_agent_create(agent_type, capabilities?, resources?)` - Create DAA agent
- `daa_capability_match(task_requirements, available_agents?)` - Match capabilities
- `daa_resource_alloc(resources, agents?)` - Resource allocation
- `daa_lifecycle_manage(agentId, action)` - Agent lifecycle
- `daa_communication(from, to, message)` - Inter-agent communication
- `daa_consensus(agents, proposal)` - Consensus mechanisms
- `daa_fault_tolerance(agentId, strategy?)` - Fault recovery
- `daa_optimization(target, metrics?)` - Performance optimization

Workflow:
- `workflow_create(name, steps, triggers?)` - Create workflow
- `workflow_execute(workflowId, params?)` - Execute workflow
- `workflow_export(workflowId, format?)` - Export workflow
- `workflow_template(action, template?)` - Manage templates
- `automation_setup(rules)` - Setup automation rules
- `pipeline_create(config)` - Create CI/CD pipelines
- `scheduler_manage(action, schedule?)` - Task scheduling
- `trigger_setup(events, actions)` - Event triggers
- `batch_process(items, operation)` - Batch processing
- `parallel_execute(tasks)` - Parallel execution
- `sparc_mode(mode, task_description, options?)` - SPARC development modes

Analysis:
- `performance_report(format?, timeframe?)` - Performance reports
- `bottleneck_analyze(component?, metrics?)` - Find bottlenecks
- `token_usage(operation?, timeframe?)` - Token consumption
- `benchmark_run(suite?)` - Run benchmarks
- `metrics_collect(components?)` - Collect metrics
- `trend_analysis(metric, period?)` - Analyze trends
- `cost_analysis(timeframe?)` - Cost/resource analysis
- `quality_assess(target, criteria?)` - Quality assessment
- `error_analysis(logs?)` - Error patterns
- `usage_stats(component?)` - Usage statistics
- `health_check(components?)` - System health

System:
- `terminal_execute(command, args?)` - Execute commands
- `config_manage(action, config?)` - Configuration management
- `features_detect(component?)` - Feature detection
- `security_scan(target, depth?)` - Security scanning
- `backup_create(destination?, components?)` - Create backups
- `restore_system(backupId)` - System restoration
- `log_analysis(logFile, patterns?)` - Log analysis
- `diagnostic_run(components?)` - Run diagnostics
- `query_control(action, queryId, model?, permissionMode?)` - Control queries
- `query_list(includeHistory?)` - List active queries

### NixOS MCP (`mcp__nixos__*`)

NixOS:
- `nixos_search(query, type, channel)` - Search packages, options, or programs
- `nixos_info(name, type, channel)` - Get detailed info about packages/options
- `nixos_stats(channel)` - Package and option counts
- `nixos_channels()` - List all available channels
- `nixos_flakes_search(query)` - Search community flakes
- `nixos_flakes_stats()` - Flake ecosystem statistics

Version History:
- `nixhub_package_versions(package, limit)` - Get version history with commit hashes
- `nixhub_find_version(package, version)` - Smart search for specific versions

Home Manager:
- `home_manager_search(query)` - Search user config options
- `home_manager_info(name)` - Get option details (with suggestions)
- `home_manager_stats()` - See what's available
- `home_manager_list_options()` - Browse all categories
- `home_manager_options_by_prefix(prefix)` - Explore options by prefix

Darwin:
- `darwin_search(query)` - Search macOS options
- `darwin_info(name)` - Get option details
- `darwin_stats()` - macOS configuration statistics
- `darwin_list_options()` - Browse all categories
- `darwin_options_by_prefix(prefix)` - Explore macOS options

### Context7 MCP (`mcp__context7__*`)
- `resolve-library-id(query, libraryName)` - Resolve library name to Context7-compatible ID
- `query-docs(libraryId, query)` - Get documentation for a library (e.g., /mongodb/docs, /vercel/next.js)

### Skills (`superpowers:*`)
- `using-superpowers` - Introduction to skills system
- `brainstorming` - Structured ideation process
- `writing-plans` - Create implementation plans
- `executing-plans` - Execute written plans
- `systematic-debugging` - Methodical bug investigation
- `test-driven-development` - TDD workflow
- `verification-before-completion` - Verify work before finishing
- `requesting-code-review` - Request review from user
- `receiving-code-review` - Process review feedback
- `finishing-a-development-branch` - Complete branch workflow
- `using-git-worktrees` - Git worktree workflows
- `dispatching-parallel-agents` - Spawn parallel agents
- `subagent-driven-development` - Agent-based development
- `writing-skills` - Create new skills

## When to Use

Swarms:
- Multi-component tasks (3+ distinct parts)
- Parallel workloads
- Complex coordination needed

Memory:
- Session start: check for existing context
- During work: store decisions, preferences, architecture choices
- Cross-session persistence needed

Neural:
- Pattern learning from successful operations
- Prediction/inference tasks
- Cognitive analysis

GitHub:
- Repository analysis
- PR management, code review
- Multi-repo coordination
- Release management

DAA:
- Autonomous agent workflows
- Knowledge sharing between agents
- Fault-tolerant operations

Workflow:
- Repeatable task sequences
- CI/CD pipeline creation
- Automation rules

Analysis:
- Performance bottlenecks
- Token usage optimization
- Quality assessment

Context7:
- Library/framework documentation lookup

NixOS MCP:
- Package/option search
- Home Manager configuration
- Finding specific package versions
- Flake discovery

Skills:
- systematic-debugging: methodical bug investigation
- test-driven-development: TDD workflow
- brainstorming: structured ideation
- writing-plans: before complex implementations
- verification-before-completion: ensure quality

## How to Use

### Memory

At session start, check for existing context:
```
mcp__claude-flow__memory_search { pattern: "project/*" }
```

Store during work:
- Project decisions and rationale
- Architecture choices made
- User preferences learned
- Task outcomes for future reference

```
mcp__claude-flow__memory_usage {
  action: "store",
  namespace: "project",
  key: "decision/auth-method",
  value: "chose JWT over sessions because..."
}
```

Retrieve when relevant context exists:
```
mcp__claude-flow__memory_usage { action: "retrieve", key: "decision/auth-method" }
```

### Swarms

Batch independent operations in a single message:

```
[Single message]
- mcp__claude-flow__swarm_init
- mcp__claude-flow__agent_spawn (researcher)
- mcp__claude-flow__agent_spawn (coder)
- Task("researcher agent instructions")
- Task("coder agent instructions")
- TodoWrite with all todos
- Read file1, Read file2, Read file3
```

Do not split related operations across multiple messages.

Scale agents to task complexity:
- Simple (1-3 components): 3-4 agents
- Medium (4-6 components): 5-7 agents
- Complex (7+ components): 8-12 agents

Always include at least one coordinator agent.

Workflow:
1. Initialize swarm with topology (mesh, hierarchical, ring, star)
2. Spawn agents based on task complexity
3. Orchestrate task with strategy (parallel, sequential, adaptive)
4. Claude Code executes using native tools
5. Store results in memory for cross-session persistence

### Agent Coordination

Spawned agents must use claude-flow hooks:

```bash
# Before starting work
npx claude-flow@alpha hooks pre-task --description "[task]"

# After file operations
npx claude-flow@alpha hooks post-edit --file "[filepath]"

# Share progress
npx claude-flow@alpha hooks notify --message "[status]"

# After completing work
npx claude-flow@alpha hooks post-task --task-id "[task]"
```

### NixOS MCP

Search for packages:
```
mcp__nixos__nixos_search { query: "neovim", search_type: "packages" }
```

Get package details:
```
mcp__nixos__nixos_info { name: "neovim", type: "package" }
```

Search NixOS options:
```
mcp__nixos__nixos_search { query: "services.openssh", search_type: "options" }
```

Search Home Manager options:
```
mcp__nixos__home_manager_search { query: "programs.git" }
```

Get HM option details:
```
mcp__nixos__home_manager_info { name: "programs.git.enable" }
```

Find specific package version:
```
mcp__nixos__nixhub_find_version { package_name: "nodejs", version: "18.0.0" }
```

### Context7

Always resolve library ID first, then query:
```
mcp__context7__resolve-library-id {
  libraryName: "react",
  query: "how to use hooks"
}
```

Then query with the returned library ID:
```
mcp__context7__query-docs {
  libraryId: "/facebook/react",
  query: "useEffect cleanup function"
}
```

### Neural

Train patterns from successful operations:
```
mcp__claude-flow__neural_train {
  pattern_type: "coordination",
  training_data: "successful task completion data",
  epochs: 50
}
```

Make predictions based on learned patterns:
```
mcp__claude-flow__neural_predict { modelId: "model-id", input: "context" }
```

### GitHub

Analyze repository:
```
mcp__claude-flow__github_repo_analyze { repo: "owner/repo", analysis_type: "code_quality" }
```

Manage PRs:
```
mcp__claude-flow__github_pr_manage { repo: "owner/repo", pr_number: 123, action: "review" }
```

### DAA

Create autonomous agent:
```
mcp__claude-flow__daa_agent_create { agent_type: "researcher", capabilities: ["search", "analyze"] }
```

Enable fault tolerance:
```
mcp__claude-flow__daa_fault_tolerance { agentId: "agent-id", strategy: "recovery" }
```

### Workflow

Create reusable workflow:
```
mcp__claude-flow__workflow_create {
  name: "deploy-pipeline",
  steps: [{ action: "test" }, { action: "build" }, { action: "deploy" }],
  triggers: ["push"]
}
```

Execute workflow:
```
mcp__claude-flow__workflow_execute { workflowId: "workflow-id", params: {} }
```

### Analysis

Generate performance report:
```
mcp__claude-flow__performance_report { format: "summary", timeframe: "24h" }
```

Find bottlenecks:
```
mcp__claude-flow__bottleneck_analyze { metrics: ["response_time", "throughput"] }
```

Check token usage:
```
mcp__claude-flow__token_usage { timeframe: "24h" }
```

### Superpowers

Invoke skills via the Skill tool:
```
Skill { skill: "superpowers:systematic-debugging" }
```

Skills are invoked BEFORE any action. If a skill has a checklist, create TodoWrite items for each step.

## References

Claude Code:
- GitHub: https://github.com/anthropics/claude-code
- Docs: https://platform.claude.com/docs/en/home

Claude Flow:
- GitHub/Docs: https://github.com/ruvnet/claude-flow/tree/main/docs
- Wiki: https://github.com/ruvnet/claude-flow/wiki

NixOS MCP:
- GitHub: https://github.com/utensils/mcp-nixos

Context7:
- GitHub/Docs: https://github.com/upstash/context7/tree/master/docs
- Docs: https://context7.com/docs

Superpowers:
- GitHub/Docs: https://github.com/obra/superpowers/tree/main/docs
