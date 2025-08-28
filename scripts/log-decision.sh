#!/bin/bash
# Log an architectural decision

DECISION="$1"
REASONING="$2"
DATE=$(date '+%Y-%m-%d')
TIMESTAMP=$(date -Iseconds)

if [ -z "$DECISION" ]; then
    echo "Usage: $0 'Decision description' ['Reasoning (optional)']"
    echo ""
    echo "Example: $0 'Use NATS instead of Redis' 'Better persistence and replay capabilities'"
    exit 1
fi

if [ -z "$REASONING" ]; then
    REASONING="Decision made during development"
fi

echo "📋 Logging architectural decision..."

# Generate decision ID
DECISION_ID="dec-$(date +%Y%m%d)-$(printf "%03d" $(($(jq length .claude/decisions-log.json 2>/dev/null || echo 0) + 1)))"

# Update decisions-log.json
if [ -f .claude/decisions-log.json ]; then
    jq --arg id "$DECISION_ID" --arg date "$DATE" --arg decision "$DECISION" --arg reasoning "$REASONING" --arg timestamp "$TIMESTAMP" \
        '. += [{
            "id": $id,
            "date": $date,
            "decision": $decision,
            "reasoning": $reasoning,
            "impact": "To be determined",
            "status": "accepted",
            "timestamp": $timestamp
        }]' .claude/decisions-log.json > tmp.json && mv tmp.json .claude/decisions-log.json
else
    echo "[{\"id\": \"$DECISION_ID\", \"date\": \"$DATE\", \"decision\": \"$DECISION\", \"reasoning\": \"$REASONING\", \"impact\": \"To be determined\", \"status\": \"accepted\", \"timestamp\": \"$TIMESTAMP\"}]" > .claude/decisions-log.json
fi

# Append to DECISIONS.md in proper ADR format
ADR_NUMBER=$(grep -c "^## ADR-" DECISIONS.md 2>/dev/null || echo "0")
ADR_NUMBER=$((ADR_NUMBER + 1))

cat >> DECISIONS.md << EOF

---

## ADR-$(printf "%03d" $ADR_NUMBER): $DECISION
**Date**: $DATE  
**Status**: Accepted  
**Context**: Decision made during development  
**Decision**: $DECISION  
**Consequences**: 
- ✅ $REASONING
- ❌ To be evaluated during implementation

**Alternatives Considered**: To be documented if relevant

**Note**: Added via log-decision.sh script

EOF

echo "✅ Decision logged with ID: $DECISION_ID"
echo "📝 Added to DECISIONS.md as ADR-$(printf "%03d" $ADR_NUMBER)"

# Update context if available
if [ -f .claude/context.json ]; then
    jq --arg decision "$DECISION" --arg id "$DECISION_ID" \
        '.lastDecision = {decision: $decision, id: $id, timestamp: now | todate}' \
        .claude/context.json > tmp.json && mv tmp.json .claude/context.json
fi

# Show recent decisions
echo ""
echo "📊 Recent decisions:"
jq -r '.[-3:][] | "  \(.id): \(.decision)"' .claude/decisions-log.json 2>/dev/null || echo "  No previous decisions found"

# Auto-commit if in git repo
if [ -d .git ]; then
    echo ""
    echo "📝 Auto-committing decision..."
    git add DECISIONS.md .claude/decisions-log.json >/dev/null 2>&1 || true
    git commit -m "decision: $DECISION" >/dev/null 2>&1 || true
    echo "✅ Decision committed to git"
fi

echo ""
echo "💡 View all decisions: cat DECISIONS.md"