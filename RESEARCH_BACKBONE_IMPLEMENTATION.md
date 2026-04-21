# Research Backbone Creation Flow - Implementation Guide

## Problem
The AI research backbone generation process was stopping after users input problem, SDG/idea, and approach. There was no UI to collect these inputs, generate the backbone, and allow users to edit the results.

## Solution
Created a complete flow that allows users to:
1. Input community problem, research idea/SDG, and approach
2. Generate AI-guided backbone (title, methodology, SDG alignment, feasibility, impact)
3. Edit the generated fields to leverage their own skills
4. Save the customized backbone

## Files Created

### 1. API Service Enhancement
**File:** `apps/mobile_flutter/lib/services/api_service.dart`
- Added `generateResearchBackbone()` method to call the backend `/research/backbone/generate` endpoint
- Handles serialization of inputs and deserialization of ResearchBackbone response

### 2. Use Case Layer
**File:** `apps/mobile_flutter/lib/features/neural_mapper/application/usecases/generate_research_backbone_use_case.dart`
- `GenerateResearchBackboneInput`: Structured input class
- `GenerateResearchBackboneUseCase`: Orchestrates backbone generation via repository

### 3. Domain Layer
**File:** `apps/mobile_flutter/lib/features/neural_mapper/domain/repositories/research_repository.dart`
- `ResearchRepository`: Abstract interface for research operations

### 4. Data Layer
**File:** `apps/mobile_flutter/lib/features/neural_mapper/data/repositories/api_research_repository.dart`
- `ApiResearchRepository`: Implements ResearchRepository, delegates to ApiService

### 5. Presentation Layer
**File:** `apps/mobile_flutter/lib/features/neural_mapper/presentation/research_backbone_create_page.dart`
- `ResearchBackboneCreatePage`: Full UI for backbone creation and editing
- Two-phase flow:
  - **Phase 1:** Input collection (problem, idea, approach)
  - **Phase 2:** Display and edit generated backbone

## UI Features

### Input Phase
- Three text fields for problem, idea/SDG, and approach
- Validation (minimum character requirements)
- "Generate Backbone" button with loading state
- Error display

### Backbone Display Phase
- **Editable Fields** (marked with "Editable" badge):
  - Research Title
  - Methodology
  - Community Impact Level
- **Read-Only Fields** (marked with "AI-Generated" badge):
  - SDG Alignment
  - Feasibility Score (cost, time, data availability)
- "Save Backbone" button to return edited backbone to caller

## User Skills Leverage
Users can:
- Modify AI-generated titles to better reflect their vision
- Refine methodology based on their expertise
- Adjust impact level assessment
- Keep or override AI suggestions for SDGs and feasibility

## Integration Points

### To use in your app:
```dart
// Navigate to backbone creation
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => ResearchBackboneCreatePage(
      studentId: userId,
    ),
  ),
).then((backbone) {
  if (backbone != null) {
    // Handle the returned ResearchBackbone
    print('Backbone saved: ${backbone.researchTitle}');
  }
});
```

## Backend Dependency
Requires the FastAPI endpoint to be running:
- `POST /api/v1/research/backbone/generate`
- Expects: `student_id`, `problem`, `sdg_or_idea`, `approach`
- Returns: `ResearchBackbone` with all fields

## Next Steps
1. Integrate this page into your main navigation flow
2. Connect it to the research post creation workflow
3. Add persistence to save backbones to Firestore
4. Consider adding a "View History" feature for previously created backbones
