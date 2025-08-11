# Course Content Workspace - MATH2025FA25

This workspace contains course content for MATH 2025 Fall 2025. The project is a Quarto website with course materials managed through a GitHub repository.

## Project Details
- **Source Repository**: https://github.com/EricFriedlander/MAT212WI25
- **New Repository**: https://github.com/MATH2025FA25/MATH2025FA25
- **Technology Stack**: Quarto website with Netlify deployment
- **Course Transition**: MAT-212 (3-week intensive) → MATH-2025 (semester-long)
- **Schedule Change**: Daily 2-hour classes → Twice weekly 75-minute classes
- **Content Updates**: Schedule, lectures, assignments, syllabus

## Development Workflow
1. Fork existing course repository ✓
2. Update content for new semester
3. Maintain website structure
4. Version control through Git

## Common Tasks
- **Preview Website**: Use "Quarto Preview" task or run `quarto preview`
- **Build Website**: Run `quarto render`
- **Update Course Info**: Edit `_quarto.yml`, `index.qmd`, `syllabus.qmd`
- **Modify Schedule**: Edit `schedule.qmd` and `schedule.xlsx`

## Workspace Setup Complete
- [x] Repository forked and configured
- [x] Course information updated (MATH 2025, Fall 2025)
- [x] Class schedule updated (MW 1:35-2:50pm, CML 208)
- [x] Quarto website building successfully
- [x] VS Code task created for development
- [x] Netlify deployment working (https://math2025fa25.netlify.app/)
- [x] Git workflow configured with Personal Access Token
- [x] Documentation complete (README.md)

## Next Steps - Content Development Priority
Ready for course content development. Focus areas in order of importance:

### 🔥 Immediate (Course Basics)
1. **Update Syllabus** (`syllabus.qmd`)
   - Change course number: MAT-212 → MATH-2025
   - Update meeting times: MW 1:35-2:50pm
   - Adjust course calendar for semester length
   - Update assignment due dates for new timeline

2. **Fix Index Page** (`index.qmd`)
   - Remove reference to "MAT-212 rather than MAT-125" in catalog description
   - Update to reference MATH-2025 appropriately

3. **Adapt Schedule** (`schedule.qmd` and `schedule.xlsx`)
   - Transform from 3-week intensive (15 days) to semester format (~30 classes)
   - Redistribute content across 15 weeks
   - Adjust pacing for 75-minute classes vs 2-hour classes

### 📚 Secondary (Content Adjustment)
4. **Review Assignment Timeline** (`hw/` directory)
   - Spread assignments across semester timeline
   - Adjust difficulty progression for longer timeframe

5. **Modify Lecture Slides** (`slides/` directory)
   - Adapt content for 75-minute format
   - Consider breaking longer sessions into multiple days

6. **Update Application Exercises** (`ae/` directory)
   - Adjust pacing for new schedule format

## Development Commands
- **Preview site**: Use VS Code task "Quarto Preview" or `quarto preview`
- **Build site**: `quarto render`
- **Deploy**: Automatic on git push to main branch
