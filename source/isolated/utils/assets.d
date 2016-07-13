module isolated.utils.assets;

import std.stdio;
import core.stdc.stdlib;
import core.memory : GC;
import core.stdc.string;

template ResourceManager(AssetType, alias loadFunc, alias freeFunc, string imports)
{
	mixin("import " ~ imports ~ ";");

	struct Handle {
		AssetType* asset = null;
		string asset_name = null;

		@property ref AssetType get() {
			return *asset;
		}

		@property ref AssetType get() const {
			return *(cast(AssetType *)asset);
		}

		alias get this;

		@property bool initialized() {
			return asset !is null;
		}

		this(this) {
			(*referenceCount)++;
		}

		~this() {
			//if(referenceCount !is null)
				(*referenceCount)--;
		}

		void opAssign(Handle handle) {
			(*referenceCount)--;

			referenceCount = handle.referenceCount;
			(*referenceCount)++;

			asset = handle.asset;
			asset_name = handle.asset_name;
		}

		size_t *referenceCount = null;
	}

	Handle[] resources;
	int[string] resourcesByName;

	Handle add(AssetType asset, out int index) {
		Handle handle;
		handle.asset = cast(AssetType*)malloc(AssetType.sizeof);
		GC.addRange(handle.asset, AssetType.sizeof, typeid(AssetType));
		*handle.asset = asset;

		handle.referenceCount = cast(size_t*)malloc(size_t.sizeof);
		*handle.referenceCount = 1;

		index = resources.length;
		resources ~= handle;

		return handle;
	}

	Handle add(AssetType asset) {
		int discard;
		return add(asset, discard);
	}

	void purge() {
		foreach(ref handle; resources) {
			if(*handle.referenceCount == 0) {
				freeFunc(*handle.asset);
				.destroy(*handle.asset);
				GC.removeRange(handle.asset);

				AssetType asset = *handle.asset;
				free(handle.asset);
				handle.asset = null;
				free(handle.referenceCount);

				if(handle.asset_name !is null) {
					resourcesByName.remove(handle.asset_name);
				}
			}
		}
	}

	ref Handle get(Args...)(string asset_name, Args args) {
		int* resource = asset_name in resourcesByName;

		if(resource is null) {
			AssetType asset = loadFunc(asset_name, args);

			int index;
			Handle r = add(asset, index);
			resources[index].asset_name = asset_name;

			resourcesByName[asset_name] = index;

			return resources[index];
		} else {
			return resources[*resource];
		}
	}
}

/*import std.typecons;
import isolated.utils.logger;
import std.conv;
import isolated.graphics.texture;

template ResourceManager(ResourceType, alias FreeFunction) {
	struct HandleImpl {
		@property const ref ResourceType get() {
			Logger.info(to!string(typeid(ResourceType)) ~ ", Accessing slot : " ~ to!string(slot) ~ " and has length of : " ~ to!string(resources.length));
			return resources[slot];
		}

		alias get this;

		size_t slot = -1;

		@property bool isInitialized() {
			return slot != -1;
		}

		~this() {
			FreeFunction(resources[slot]);
			resources[slot] = ResourceType.init;
		}
	}

	alias Handle = RefCounted!HandleImpl;

	ResourceType[] resources;

	Handle add(ResourceType resource)
	{
		// Find an empty slot in the resources array, put the resource there, and return a handle pointing to that slot.
		int slot = -1;

		foreach(i, r; resources) {
			if(r == ResourceType.init) {
				slot = i;
				resources[i] = resource;
				break;
			}
		}

		if(slot == -1) {
			slot = resources.length;
			resources ~= resource;
		}

		return Handle(slot);
	}

	ResourceType getActualResource(Handle handle) {
		return resources[handle.slot];
	}

	void update(Handle handle, ResourceType newResource) {
		FreeFunction(resources[handle.slot]);
		resources[handle.slot] = newResource;
	}
}

template ResourceCache(ResourceType, alias load, alias free, string imports)
{
	mixin("import " ~ imports ~ ";");

	alias Manager = ResourceManager!(ResourceType, free);

	Manager.Handle[string] cache;

	Manager.Handle get(Args...)(string name, Args args)
	{
		Manager.Handle *handle = name in cache;
		if(handle !is null)
			return *handle;

		Manager.Handle h = Manager.add(load(name, args));
		cache[name] = h;

		Logger.info("Loading : " ~ name ~ " width id : " ~ to!string(h.slot));

		return h;
	}

	void purge()
	{
		// the keys property allocates a new array with the AA keys, which is important since we're modifying the AA.
		foreach(key; cache.keys)
		{
			// This is the part you were actually interested in. It's important to take a pointer to the handle here, and not reference it directly. I had some issues with that in the past, I'm not sure if that's still the case.
			auto ptr = key in cache;
			if(ptr.refCountedStore.refCount == 1) // If this is the last reference
			{
				destroy(*ptr); // I'm not sure if this is still necessary, there was some issue with AAs in the past. It may be fixed today. Destroying the handle doesn't hurt either way so I left it in.
				cache.remove(key);
			}
		}
	}
}*/
