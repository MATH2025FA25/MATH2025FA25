# MATH 2025: Multiple Regression Analysis - Fall 2025

This repository contains the course website and materials for MATH 2025 - Multiple Regression Analysis at the College of Idaho, Fall 2025, taught by Dr. Eric Friedlander.

## Course Transition

This course is being transitioned from:
- **Previous**: MAT 212 (3-week intensive, daily 2-hour classes)  
- **Current**: MATH 2025 (semester-long, twice weekly 75-minute classes)

## Technology Stack

- **Website Framework**: [Quarto](https://quarto.org/)
- **Deployment**: Netlify
- **Version Control**: Git/GitHub
- **Development Environment**: RStudio/VS Code

## Local Development

### Prerequisites
- [Quarto](https://quarto.org/docs/get-started/) installed
- [R](https://www.r-project.org/) and [RStudio](https://posit.co/download/rstudio-desktop/) (optional but recommended)

### Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/MATH2025FA25/MATH2025FA25.git
   cd MATH2025FA25
   ```

2. **Preview the website locally**:
   ```bash
   quarto preview
   ```
   This will start a local development server and open the website in your browser.

3. **Build the website**:
   ```bash
   quarto render
   ```

### VS Code Tasks

The workspace includes a VS Code task for convenient development:
- **Quarto Preview**: Starts the local development server

Access via: `Ctrl+Shift+P` → "Tasks: Run Task" → "Quarto Preview"

## Project Structure

```
├── .github/                    # GitHub configuration and workflows
├── ae/                        # Application exercises  
├── data/                      # Course datasets
├── exam/                      # Exam materials
├── hw/                        # Homework assignments
├── images/                    # Course images and assets
├── prepare/                   # Preparation materials
├── project/                   # Course project materials
├── slides/                    # Lecture slides
├── _quarto.yml               # Main Quarto configuration
├── index.qmd                 # Course homepage
├── schedule.qmd              # Course schedule
├── syllabus.qmd             # Course syllabus
└── README.md                # This file
```

## Content Updates Needed

### High Priority
- [ ] Update course schedule for semester format (schedule.qmd)
- [ ] Modify syllabus for new course number and format (syllabus.qmd)  
- [ ] Adjust assignment due dates for new schedule
- [ ] Update lecture slides for 75-minute format

### Medium Priority
- [ ] Review and update homework assignments
- [ ] Adjust project timeline
- [ ] Update application exercises for new pacing

### Low Priority
- [ ] Update course branding/images
- [ ] Refine course policies for semester format

## Deployment

The website is automatically deployed to Netlify when changes are pushed to the main branch.

- **Live Site**: https://math2025fa25.netlify.app/
- **GitHub Repository**: https://github.com/MATH2025FA25/MATH2025FA25

## Common Tasks

### Adding New Content
1. Create/edit `.qmd` files for new pages
2. Update `_quarto.yml` if adding to navigation
3. Preview changes locally with `quarto preview`
4. Commit and push changes to deploy

### Updating the Schedule
- Edit `schedule.qmd` for the main schedule page
- Update `schedule.xlsx` for data-driven schedule elements

### Modifying Course Information
- Course title/description: `_quarto.yml` and `index.qmd`
- Syllabus: `syllabus.qmd`
- Course policies: `support.qmd`

## License

This course content is licensed for educational use. Please contact Dr. Eric Friedlander for permissions regarding reuse or distribution.
