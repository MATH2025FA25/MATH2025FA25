# MATH 2025 Course Development Status

**Date**: August 11, 2025
**Status**: Infrastructure Complete, Ready for Content Development

## ✅ Completed Infrastructure

### Repository & Deployment
- [x] Forked MAT212WI25 → MATH2025FA25 organization repository
- [x] Git remote configured: `https://github.com/MATH2025FA25/MATH2025FA25`
- [x] Netlify deployment working: `https://math2025fa25.netlify.app/`
- [x] Automatic deployment on git push configured

### Course Information Updates
- [x] Course title: MAT 212 → MATH 2025
- [x] Semester: Winter 2025 → Fall 2025  
- [x] Meeting time: MW 1:35-2:50pm (updated from daily 2-hour intensive)
- [x] Location: CML 208
- [x] All repository URLs updated in `_quarto.yml`

### Development Environment
- [x] VS Code workspace configured
- [x] "Quarto Preview" task available (run with Ctrl+Shift+P → Tasks: Run Task)
- [x] Git authentication working (Personal Access Token)
- [x] Local rendering confirmed working

## 🎯 Immediate Next Steps (Priority Order)

When you return to work on this:

### 1. Update Syllabus (HIGH PRIORITY)
**File**: `syllabus.qmd`
**Changes needed**:
- Course number: MAT-212 → MATH-2025
- Meeting schedule: Update to MW 1:35-2:50pm  
- Course calendar: Adapt from 3-week to ~15-week semester
- Assignment dates: Redistribute across semester timeline

### 2. Fix Course Description (HIGH PRIORITY)
**File**: `index.qmd` (lines ~11)
**Issue**: Still says "take MAT-212 rather than MAT-125"
**Fix**: Update to reference MATH-2025

### 3. Schedule Transformation (HIGH PRIORITY)  
**Files**: `schedule.qmd`, `schedule.xlsx`
**Challenge**: Convert 3-week intensive (daily 2-hour) → semester (MW 75-min)
**Impact**: Major restructuring of content timing and pacing

## 📂 Key Files to Modify
- `syllabus.qmd` - Course policies and calendar
- `index.qmd` - Course description fix
- `schedule.qmd` - Main schedule page
- `schedule.xlsx` - Schedule data
- `hw/*.qmd` - Assignment timelines (secondary priority)
- `slides/*.qmd` - Lecture content adaptation (secondary priority)

## 🚀 Quick Start Commands
```bash
# Preview site locally
quarto preview

# Build site
quarto render

# Git workflow
git add .
git commit -m "Description of changes"
git push
```

## 📝 Notes
- Original MAT212WI25 repository unchanged and preserved
- All infrastructure working - focus purely on content now
- Biggest challenge will be schedule adaptation from intensive to semester format
- Consider semester start date when updating calendar/assignment dates
