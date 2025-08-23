# Course Content Workspace - MATH2025FA25

This workspace contains course content for MATH 2025 Fall 2025. The project is a Quarto website with course materials managed through a GitHub repository.

---

## Global Principles

- **Ask clarifying questions.** When requirements are ambiguous, seek clarification before proceeding. Always ask questions one at a time.
- **Updating instruction file.** Keep the instruction file up to date with any changes made to the workflow or project structure.

---

## Project Details
- **Repository**: https://github.com/MATH2025FA25/MATH2025FA25
- **Technology Stack**: Quarto website with Netlify deployment
- **Course Transition**: MAT-212 (3-week intensive) → MATH-2025 (semester-long)
- **Schedule Change**: Daily 2-hour classes → Twice weekly 75-minute classes
- **Content Updates**: Schedule, lectures, assignments, syllabus

---

## Development Workflow
1. Fork existing course repository ✓
2. Update content for new semester
3. Maintain website structure
4. Version control through Git

---

## Common Tasks
- **Preview Website**: Use "Quarto Preview" task or run `quarto preview`
- **Build Website**: Run `quarto render`. Note that this will re-generate all output files. If only one file needs to be re-rendered, use `quarto render <file.qmd>`.
- **Update Course Info**: Edit `_quarto.yml`, `index.qmd`, `syllabus.qmd`
- **Modify Schedule**: Edit `schedule.qmd` and `schedule.xlsx`

---

## Workspace Setup Complete
- [x] Repository forked and configured
- [x] Course information updated (MATH 2025, Fall 2025)
- [x] Class schedule updated (MW 1:35-2:50pm, CML 208)
- [x] Quarto website building successfully
- [x] VS Code task created for development
- [x] Netlify deployment working (https://math2025fa25.netlify.app/)
- [x] Git workflow configured with Personal Access Token
- [x] Documentation complete (README.md)

---

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

---

## Development Commands
- **Preview site**: Use VS Code task "Quarto Preview" or `quarto preview`
- **Build site**: `quarto render`
- **Deploy**: Automatic on git push to main branch

---

## Folder and File Meanings
- **ae/**: Contains Activities meant to be completed in class.
- **data/**: Contains datasets that are relevant to the class.
- **Exam/**: Contains any information relevant to exams but not the exams themselves.
- **hw/**: Contains homework assignments.
- **images/**: Contains relevant images.
- **prepare/**: Contains reading assignments.
- **project/**: Contains all relevant information for projects.
- **slides/**: Contains all of the lecture slides.

All assignments (readings, activities, hws, and projects) and slides are published to the schedule page. This is built using the `schedule.qmd` file; however, the `schedule.xlsx` file dictates what should actually be published.

---

## Schedule.xlsx Column Definitions
Each row corresponds to one class day of the week and will usually correspond to a class period but not always (e.g. if an assignment is due on a day during which there is no lecture). There are 12 columns in this Excel file:

1. **Publish**: This column receives an x if the content should be published and is blank otherwise. This column is not displayed on the webpage.
2. **Lecture**: The number of the lecture (e.g., 1, 2, 3, etc.). If there is no lecture on that day, this should be left blank.
3. **DOW**: The day of the week (e.g., M, T, W, TH, F).
4. **Date**: The date of the class in the format MM/DD/YYYY.
5. **Topic**: The topics of the class or other relevant information. This is frequently the title of the slides but may need to be shortened if the title is too long.
6. **Prepare**: The reading assignments to be completed before that class period. Each one should reference a quarto file in the prepare directory and should follow the format: `/prepare/xx-<slug>.qmd`
7. **Slides**: The location of the slides for the class. Each one should reference a quarto file in the slides directory and should follow the format: `/slides/xx-<slug>.qmd`
8. **AE**: The location of the activities for the class. Each one should reference a quarto file in the ae directory and should follow the format: `/ae/xx-<slug>.qmd`
9. **HW**: The location of the homework assignments due that day. Each one should reference a quarto file in the hw directory and should follow the format: `/hw/hw-xx.qmd`
10. **Project**: The location of the project assignments due that day. These will be left blank most of the time. Each one should reference a quarto file in the project directory and should follow the format: `/project/<slug>.qmd`
11. **Notes**: Any notes that are relevant to the class. It typically includes information about when assignments are assigned and information on when they are due (e.g., "HW 1 due/HW 2 assigned").
12. **Eric's Notes**: Notes to myself which are not published to the website.

The numbers on the activities, slides, and prepare assignments should correspond to the lecture number. However, the numbers on the homework should refer to the homework assignment number.
