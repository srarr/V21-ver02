import { StateGraph } from "@langchain/langgraph";
import { nodeArchitect } from "./nodes/architect";
import { nodeSynth } from "./nodes/synth";
import { nodeT0 } from "./nodes/t0";
import { nodePack, HSPManifest } from "./nodes/pack";
import { Blueprint, Strategy, Metrics } from "./lib/types";

export interface OrchestratorState {
  runId: string;
  blueprint?: Blueprint;
  strategies?: Strategy[];
  metrics?: Metrics;
  manifest?: HSPManifest;
}

export function buildGraph() {
  // Create state graph with defined channels
  const graph = new StateGraph<OrchestratorState>({
    channels: {
      runId: null,
      blueprint: null,
      strategies: null,
      metrics: null,
      manifest: null
    }
  });

  // Add nodes with their state transformations
  graph.addNode("architect", async (state: OrchestratorState) => ({
    ...state,
    blueprint: await nodeArchitect(state.runId)
  }));

  graph.addNode("synth", async (state: OrchestratorState) => ({
    ...state,
    strategies: await nodeSynth(state.runId, state.blueprint!)
  }));

  graph.addNode("t0", async (state: OrchestratorState) => ({
    ...state,
    metrics: await nodeT0(state.runId, state.strategies!)
  }));

  graph.addNode("pack", async (state: OrchestratorState) => ({
    ...state,
    manifest: await nodePack(state.runId, state.metrics!)
  }));

  // Define linear flow (with type casting for compatibility)
  graph.addEdge("architect" as any, "synth" as any);
  graph.addEdge("synth" as any, "t0" as any);
  graph.addEdge("t0" as any, "pack" as any);
  
  // Set entry point
  graph.setEntryPoint("architect" as any);

  // Compile the graph
  return graph.compile();
}