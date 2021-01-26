# CacheKit

CacheKit is light-weight, highly customizable cache framework for iOS and macOS.

By default, CacheKit sets up a memory cache and a disk cache for your app, while you are able to customize the memory or the disk cache. 

You can even replace either of them with your own type's instance, as long as it conforms to the required protocol.

## How to Use

### The Default Way

```swift
import class CacheKit.Cache

let cache = try? Cache(url: url)
try? cache?.set("A Codable object", by: "A String as key")
try? cache?.nsSet("An NSSecureCoding NSObject" as NSString, by: "Also a String as key")
```

> Currently, CacheKit uses String as its key type. Is it necessary and better to allow other hashable types?

When retrieving, you need to specify the correct type of the object:

```swift
let aStringObject: String? = cache?.object(by: key)
```

Use batch insertion and retrieval when there are multiple objects. This will increase the performance significantly, since CacheKit has done some optimization on batch operations.

Also, you need to specify the type of the objects. When using high level functions, you can declare the type in the first function call's closure.

```swift
let keyValuePairs = [(Object, String)](zip(keys, arrayOfObjects))
try? cache?.set(keyValuePairs)

cache?.objects(by: keys)
    .filter { (stringObject: String?) -> Bool in
        stringObject != nil
    }
    .forEach {
        // ......
    }
```

### Customize The Underneath Caches

The default behavior is, as said before, setting up a memory cache and a disk cache for you.

However, the initializer of `Cache` actually accepts a memory cache instance and a disk cache instance.

```swift
import class CacheKit.Cache
import class CacheKit.MemoryCache
import typealias CacheKit.DefaultDiskCache

let memoryCache = MemoryCache(name: "A name, for distinction")
memoryCache.trimInfo.sizeLimit = 1024 * 1024 * 10  // 10MB

let diskCache = try? DefaultDiskCache(url: url)
diskCache?.trimInfo.freeDiskSpace = 1024 * 1024 * 1024  // 1GB

let cache = try? Cache(url: url, memoryCache: memoryCache, diskCache: diskCache)
```

The built-in `MemoryCache` and `DiskCache` are both `Trimable`, which means they'll began to remove objects it has cached when they reached some threshold.

The thresholds are defined in `trimInfo`, by updating which you can change their trim behavior, as the code listed above.g

You can also provide your own memory cache or disk cache implementation when intializing `Cache`, as long as it conforms to `MemoryCaching` or `DiskCaching`.

### Use Your Own Database or File Storage

Down deeper, the default disk cache is also customizable. The `DefaultDiskCache` is a typealias of `DiskCache<FMDBInterface, FileManagerWrapper>`.

The `FMDBInterface` is a database interface based on FMDB, and `FileManagerwrapper` is merely a wrapper of the iOS `FileManager`.

You can specify the type of your own database object or file storage, conforming to `DatabaseProtocol` or `FileStorageProtocol`.

```swift
import class CacheKit.Cache
import class CacheKit.MemoryCache
import class CacheKit.DiskCache
import protocol CacheKit.DatabaseProtocol
import protocol CacheKit.FileStorageProtocol

let diskCache = try? DiskCache<MyDAO, MyFileManager>(url: url)
```
