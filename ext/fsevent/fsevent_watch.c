/* Based on the code from:
 * http://github.com/svoop/autotest-fsevent/blob/master/ext/fsevent/fsevent_sleep.c
 */
#include <CoreServices/CoreServices.h>

void callback(ConstFSEventStreamRef streamRef,
  void *clientCallBackInfo,
  size_t numEvents,
  void *eventPaths,
  const FSEventStreamEventFlags eventFlags[],
  const FSEventStreamEventId eventIds[]
) {
  // Print modified dirs
  int i;
  char **paths = eventPaths;
  for (i = 0; i < numEvents; i++) {
    if (i > 0) printf("%c", 0);
    printf("%s", paths[i]);
  }
  printf("\n");
  fflush(stdout);
}

int main(int argc, const char *argv[]) {
  // TODO: GNU getopt()
  if (argc != 2 || strncmp(argv[1], "-h", 2) == 0) {
    printf("Usage: %s /path/to/dir [/path/to/another ...]\n", argv[0]);
    exit(1);
  }
  
  int i;
  int numDirs = argc - 1;
  CFStringRef *dirs[numDirs];
  
  // Create event stream
  for (i = 1; i < argc; i++) {
    dirs[i - 1] = (CFStringRef *) CFStringCreateWithCString(
      kCFAllocatorDefault,
      argv[i],
      kCFStringEncodingUTF8
    );
  }
  CFArrayRef pathsToWatch = CFArrayCreate(NULL, (const void **)dirs, numDirs, NULL);
  
  void *callbackInfo = NULL;
  CFAbsoluteTime latency = 0.1;
  FSEventStreamRef stream = FSEventStreamCreate(
    kCFAllocatorDefault,
    callback,
    callbackInfo,
    pathsToWatch,
    kFSEventStreamEventIdSinceNow,
    latency,
    kFSEventStreamCreateFlagNone
  );
  
  // Add stream to run loop
  FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  FSEventStreamStart(stream);
  CFRunLoopRun();
  
  return 2;
}