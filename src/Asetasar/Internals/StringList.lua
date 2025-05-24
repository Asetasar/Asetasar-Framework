return {
StringList = {
    DOESNT_EXIST = "doesn't exist.",
    DEPENDENCY_FAILED_LOAD = "Dependency [%s] failed to load! Error: %s",
    FINISHED_FETCHING_DEPENDENCIES_TIME = "Finished fetching dependencies, time elapsed: %s",
    FETCHING_DEPENDENCIES_INITIAL = "Fetching dependencies...",
    DEPENDENCY_DOESNT_EXIST = "Dependency [%s] doesn't exist.",
    FAILED_LOAD_ONE_DEPENDENCY = "Failed to load dependency, Error: %s",
    FAILED_LOAD_MULTIPLE_DEPENDENCIES = "Failed to load multiple dependencies, errors:\n%s",

    INITIALIZING_SINGLETONS_INITIAL = "Initializing singletons...",
    INVALID_TYPEOF_DEPENDENCY = "Invalid typeof of dependency, table or ModuleScript expected, got %s",
    SINGLETON_FAILED_LOAD = "Singleton [%s] failed to load! Error:\n%s",
    SINGLETON_LOADED_TIME = "Singleton [%s] loaded in %s.",
    SINGLETON_LOADED_INIT_TIME = "Singleton [%s] loaded in [%s] and initialized in [%s].",
    SINGLETONS_INITIALIZED = "Singletons have been initialized, time elapsed: %s",

    MASTER_CLEANUP_INITIAL = "Cleaning up master environment...",
    MASTER_CLEANUP = "Master environemnt has been cleaned up, time elapsed: %s",
    QUEUE_ARRAY_CLEANUP = "Removed queued instances for removal.",
    MASTER_INITIALIZED = "Master has been initialized, time elapsed: %s"
}}

--// Done so I don't have to do additional stuff specifically for some modules and can just load all of them
--// By one simple loop.