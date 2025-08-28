#!/usr/bin/env node

/**
 * Todo Persistence System
 * Intercepts TodoWrite tool calls and persists todos to .claude/todos.json
 * Triggers checkpoint-manager when tasks complete
 */

const fs = require('fs');
const path = require('path');
const { execSync, spawn } = require('child_process');

// Configuration
const PROJECT_ROOT = path.resolve(__dirname, '..');
const CLAUDE_DIR = path.join(PROJECT_ROOT, '.claude');
const TODOS_FILE = path.join(CLAUDE_DIR, 'todos.json');
const CHECKPOINT_CONFIG = path.join(CLAUDE_DIR, 'checkpoint-config.json');
const AUTO_CHECKPOINT_SCRIPT = path.join(PROJECT_ROOT, 'scripts', 'auto-checkpoint.sh');

// Colors for console output
const colors = {
  green: '\x1b[32m',
  blue: '\x1b[34m', 
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  reset: '\x1b[0m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// Ensure .claude directory exists
function ensureClaudeDirectory() {
  if (!fs.existsSync(CLAUDE_DIR)) {
    fs.mkdirSync(CLAUDE_DIR, { recursive: true });
    log('✓ Created .claude directory', 'green');
  }
}

// Initialize todos.json if it doesn't exist
function initializeTodosFile() {
  if (!fs.existsSync(TODOS_FILE)) {
    const initialTodos = {
      version: "1.0",
      lastUpdated: new Date().toISOString(),
      currentPhase: "1.3",
      statistics: {
        totalTasks: 0,
        completedTasks: 0,
        completionRate: "0%"
      },
      phases: {
        "1.1": { status: "completed", tasks: [] },
        "1.2": { status: "completed", tasks: [] },
        "1.3": { status: "pending", tasks: [] },
        "1.4": { status: "pending", tasks: [] },
        "1.5": { status: "pending", tasks: [] },
        "1.6": { status: "pending", tasks: [] }
      }
    };
    
    fs.writeFileSync(TODOS_FILE, JSON.stringify(initialTodos, null, 2));
    log('✓ Initialized todos.json', 'green');
  }
}

// Load current todos
function loadTodos() {
  try {
    return JSON.parse(fs.readFileSync(TODOS_FILE, 'utf8'));
  } catch (error) {
    log(`⚠ Error loading todos: ${error.message}`, 'yellow');
    initializeTodosFile();
    return JSON.parse(fs.readFileSync(TODOS_FILE, 'utf8'));
  }
}

// Save todos to file
function saveTodos(todos) {
  try {
    todos.lastUpdated = new Date().toISOString();
    fs.writeFileSync(TODOS_FILE, JSON.stringify(todos, null, 2));
    log('✓ Saved todos to file', 'green');
    return true;
  } catch (error) {
    log(`✗ Error saving todos: ${error.message}`, 'red');
    return false;
  }
}

// Update statistics
function updateStatistics(todos) {
  let totalTasks = 0;
  let completedTasks = 0;
  
  Object.keys(todos.phases).forEach(phase => {
    const phaseTasks = todos.phases[phase].tasks || [];
    totalTasks += phaseTasks.length;
    completedTasks += phaseTasks.filter(task => task.status === 'completed').length;
  });
  
  todos.statistics = {
    totalTasks,
    completedTasks,
    completionRate: totalTasks > 0 ? `${Math.round(completedTasks * 100 / totalTasks)}%` : "0%"
  };
}

// Detect which phase a task belongs to
function detectPhaseFromTask(taskContent) {
  const phasePatterns = {
    "1.3": ["orchestrator", "architect", "synth", "t0", "pack", "event system", "sse", "langgraph"],
    "1.4": ["frontend", "svelte", "chat interface", "timeline", "portfolio", "ui"],
    "1.5": ["integration", "testing", "e2e", "contract", "playwright", "cypress"],
    "1.6": ["container", "presenter", "api client", "hooks", "type safety", "storybook"]
  };
  
  const content = taskContent.toLowerCase();
  
  for (const [phase, keywords] of Object.entries(phasePatterns)) {
    if (keywords.some(keyword => content.includes(keyword))) {
      return phase;
    }
  }
  
  return "1.3"; // Default to current phase
}

// Process TodoWrite tool call
function processTodoWrite(todoList) {
  log('📝 Processing TodoWrite tool call...', 'blue');
  
  const todos = loadTodos();
  let hasCompletedTasks = false;
  let completedTasksInfo = [];
  
  // Process each todo item
  todoList.forEach((todo, index) => {
    const phase = detectPhaseFromTask(todo.content);
    const taskId = `${phase}.${index + 1}`;
    
    // Ensure phase exists
    if (!todos.phases[phase]) {
      todos.phases[phase] = { status: "pending", tasks: [] };
    }
    
    // Find existing task or create new one
    let existingTask = todos.phases[phase].tasks.find(t => 
      t.content === todo.content || t.id === taskId
    );
    
    if (!existingTask) {
      existingTask = {
        id: taskId,
        content: todo.content,
        activeForm: todo.activeForm,
        status: todo.status,
        createdAt: new Date().toISOString()
      };
      todos.phases[phase].tasks.push(existingTask);
      log(`✓ Added new task: ${todo.content}`, 'green');
    } else {
      // Update existing task
      const oldStatus = existingTask.status;
      existingTask.status = todo.status;
      existingTask.activeForm = todo.activeForm;
      existingTask.updatedAt = new Date().toISOString();
      
      if (oldStatus !== 'completed' && todo.status === 'completed') {
        hasCompletedTasks = true;
        completedTasksInfo.push({
          phase: phase,
          task: todo.content,
          taskId: taskId
        });
        log(`✅ Task completed: ${todo.content}`, 'green');
      }
    }
  });
  
  // Update phase status based on task completion
  Object.keys(todos.phases).forEach(phase => {
    const phaseTasks = todos.phases[phase].tasks;
    if (phaseTasks.length > 0) {
      const allCompleted = phaseTasks.every(task => task.status === 'completed');
      const hasInProgress = phaseTasks.some(task => task.status === 'in_progress');
      
      if (allCompleted) {
        todos.phases[phase].status = 'completed';
      } else if (hasInProgress) {
        todos.phases[phase].status = 'in_progress';
      } else {
        todos.phases[phase].status = 'pending';
      }
    }
  });
  
  // Update current phase to first non-completed phase
  const currentPhase = Object.keys(todos.phases).find(phase => 
    todos.phases[phase].status !== 'completed'
  ) || "1.6";
  todos.currentPhase = currentPhase;
  
  updateStatistics(todos);
  saveTodos(todos);
  
  // Trigger checkpoint-manager if tasks completed
  if (hasCompletedTasks) {
    triggerCheckpointManager(completedTasksInfo);
  }
  
  return todos;
}

// Trigger checkpoint-manager when tasks complete
function triggerCheckpointManager(completedTasks) {
  log('🔄 Triggering checkpoint-manager...', 'blue');
  
  try {
    // Run checkpoint manager in background
    const child = spawn('bash', [AUTO_CHECKPOINT_SCRIPT], {
      detached: true,
      stdio: ['ignore', 'pipe', 'pipe']
    });
    
    child.unref();
    
    child.stdout.on('data', (data) => {
      log(`Checkpoint: ${data.toString().trim()}`, 'blue');
    });
    
    child.stderr.on('data', (data) => {
      log(`Checkpoint Error: ${data.toString().trim()}`, 'red');
    });
    
    child.on('close', (code) => {
      if (code === 0) {
        log('✓ Checkpoint-manager completed successfully', 'green');
      } else {
        log(`⚠ Checkpoint-manager exited with code ${code}`, 'yellow');
      }
    });
    
    // Update completed tasks log
    const completedFile = path.join(CLAUDE_DIR, 'completed.txt');
    const timestamp = new Date().toISOString().slice(0, 19).replace('T', ' ');
    
    completedTasks.forEach(task => {
      const logEntry = `[${timestamp}] [${task.phase}] ${task.task}\n`;
      fs.appendFileSync(completedFile, logEntry);
    });
    
  } catch (error) {
    log(`✗ Error triggering checkpoint-manager: ${error.message}`, 'red');
  }
}

// Watch for TodoWrite patterns in stdin (for integration with Claude Code)
function watchForTodoWrite() {
  log('👁 Watching for TodoWrite patterns...', 'blue');
  
  // This would be called by the integration system
  process.stdin.on('data', (data) => {
    try {
      const input = data.toString();
      
      // Look for TodoWrite patterns
      if (input.includes('TodoWrite') || input.includes('"todos":')) {
        const todoMatch = input.match(/\{"todos":\s*(\[.*?\])\}/s);
        if (todoMatch) {
          const todoList = JSON.parse(todoMatch[1]);
          processTodoWrite(todoList);
        }
      }
    } catch (error) {
      log(`Error processing input: ${error.message}`, 'red');
    }
  });
}

// CLI interface
function main() {
  const command = process.argv[2];
  
  ensureClaudeDirectory();
  initializeTodosFile();
  
  switch (command) {
    case 'init':
      log('📋 Todo persistence system initialized', 'green');
      break;
      
    case 'status':
      const todos = loadTodos();
      log('\n📊 Todo Status:', 'blue');
      console.log(`Current Phase: ${todos.currentPhase}`);
      console.log(`Total Tasks: ${todos.statistics.totalTasks}`);
      console.log(`Completed: ${todos.statistics.completedTasks}`);
      console.log(`Progress: ${todos.statistics.completionRate}`);
      break;
      
    case 'test':
      // Test with sample data
      const sampleTodos = [
        {
          content: "Implement Architect Mock node",
          activeForm: "Implementing Architect Mock node", 
          status: "completed"
        },
        {
          content: "Create Event System bus",
          activeForm: "Creating Event System bus",
          status: "in_progress"
        }
      ];
      processTodoWrite(sampleTodos);
      break;
      
    case 'watch':
      watchForTodoWrite();
      break;
      
    default:
      console.log(`
Todo Persistence System

Usage: node todo-persist.js [command]

Commands:
  init    - Initialize the system
  status  - Show current status
  test    - Test with sample data
  watch   - Watch for TodoWrite patterns
  
Files:
  ${TODOS_FILE}
  ${CHECKPOINT_CONFIG}
`);
  }
}

// Export functions for testing
if (require.main === module) {
  main();
} else {
  module.exports = {
    processTodoWrite,
    loadTodos,
    saveTodos,
    triggerCheckpointManager
  };
}