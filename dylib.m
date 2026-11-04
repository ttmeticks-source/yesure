#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <unistd.h>

void showInjectedPopup() {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"INJECTED BOZO!"];
        [alert setInformativeText:@"Client modified successfully."];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    });
}

__attribute__((constructor))
static void BozoInit(void) {
    showInjectedPopup();
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    int opt = 1; setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    struct sockaddr_in addr = {0}; addr.sin_family = AF_INET; addr.sin_port = htons(5599); addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    bind(fd, (struct sockaddr *)&addr, sizeof(addr)); listen(fd, 1);
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while(1) { 
            int c = accept(fd, NULL, NULL); 
            if (c < 0) continue; 
            char buf[65536]; 
            ssize_t n = read(c, buf, sizeof(buf)-1); 
            if (n > 0) { buf[n]=0; NSLog(@"[Bozo] Script: %s", buf); } 
            close(c); 
        }
    });
}
