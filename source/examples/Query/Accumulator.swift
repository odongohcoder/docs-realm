print("Projects with average tasks priority above 5: \(projects.filter("tasks.@avg.priority > 5").count)");
print("Long running projects: \(projects.filter("tasks.@sum.progressMinutes > 100").count)");
