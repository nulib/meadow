def original = [:];
for (key in ctx.keySet().toArray()) {
    if (!key.startsWith("_")){
        original[key] = ctx.get(key);
        ctx.remove(key);
    }
}
ctx.original = original;
