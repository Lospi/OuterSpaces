//
//  OuterSpaces-Bridging-Header.h
//  OuterSpaces
//

#ifndef OuterSpaces_Bridging_Header_h
#define OuterSpaces_Bridging_Header_h

#import <Foundation/Foundation.h>

int _CGSDefaultConnection();
id CGSCopyManagedDisplaySpaces(int conn);
id CGSCopyActiveMenuBarDisplayIdentifier(int conn);

#endif /* OuterSpaces_Bridging_Header_h */
