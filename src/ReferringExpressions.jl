module ReferringExpressions

using PyCall, JSON, Iterators
@pyimport cPickle as pickle
const DATADIR = Pkg.dir("ReferringExpressions","data")

struct RefExpData
    # inputs
    datadir
    dataset
    datasplit

    # storage
    imgdir
    refs
    annotations
    images
    categories
    sentences
    img2ref
    img2ann
    ref2ann
    ann2ref
    cat2ref
    sent2ref
    sent2tok

    function RefExpData(datadir, dataset, datasplit)
        dicts = (:data, :refs, :annotations, :images, :categories, :sentences,
                 :img2ref, :img2ann, :ref2ann, :ann2ref, :cat2ref, :sent2ref,
                 :sent2tok)
        for dict in dicts
            @eval $dict = Dict()
        end

        imgdir = _get_image_dir(datadir, dataset)
        data["dataset"] = dataset
        data["refs"] = _load_refs(datadir, dataset, datasplit)
        instances = _get_instances(datadir, dataset)
        data["images"] = instances["images"]
        data["annotations"] = instances["annotations"]
        data["categories"] = instances["categories"]

        for ann in data["annotations"]
            id, iid = ann["id"], ann["image_id"]
            annotations[id] = ann
            img2ann[iid] = vcat(get(img2ann, iid, []), ann)
        end

        for img in data["images"]
            images[img["id"]] = img
        end

        for cat in data["categories"]
            categories[cat["id"]] = cat["name"]
        end

        for ref in data["refs"]
            ref_id = ref["ref_id"]
            ann_id = ref["ann_id"]
            category_id = ref["category_id"]
            image_id = ref["image_id"]

            refs[ref_id] = ref
            img2ref[image_id] = vcat(get(img2ref, image_id, []), ref)
            cat2ref[category_id] = vcat(get(cat2ref, category_id, []), ref)
            ref2ann[ref_id] = annotations[ann_id]
            ann2ref[ann_id] = ref

            for sent in ref["sentences"]
                sent_id = sent["sent_id"]
                sentences[sent_id] = sent
                sent2ref[sent_id] = ref
                sent2tok[sent_id] = sent["tokens"]
            end
        end

        return new(datadir,dataset,datasplit,imgdir,refs,annotations,
                   images,categories,sentences,img2ref,img2ann,ref2ann,
                   ann2ref,cat2ref,sent2ref,sent2tok)
    end

    RefExpData(dataset, datasplit) = RefExpData(DATADIR, dataset, datasplit)
end
export RefExpData

# load methods
for obj in (:refs, :annotations, :images, :categories)
    fun = Symbol(:load_, obj)
    @eval begin
        $fun{T<:Int}(d::RefExpData, id::T) = [d.$(obj)[id]]
        $fun{T<:Array}(d::RefExpData, ids::T) = map(id->d.$(obj)[id], ids)
        export $fun
    end
end

# filter methods
function filter_refs_by_split(d::RefExpData, split="")
    isempty(split) && return d.refs
    if in(split, ("testA","testB","testC"))
        refs = filter((k,v) -> in(string(split[end]), v["split"]), d.refs)
    elseif in(split, ("testAB","testBC","testAC"))
        refs = filter((k,v) -> v["split"] == split, d.refs)
    elseif in(split, ("train","valid","test"))
        refs = filter((k,v) -> startswith(v["split"], split), d.refs)
    end
    return refs
end
export filter_refs_by_split

_filters = (:categories, :refs)
_arrays = (:ref, :image, :annotation)
for (_filter, _array) in product(_filters, _arrays)
    F = Symbol(:filter_, _array, :s_by_, _filter)
    K = Symbol(_filter, "_id"); A = Symbol(K, :s)
    @eval $F(d::RefExpData, ids) = filter((k,v) -> in(v["$K"], ids) , d.$A)
    @eval $F(data, ids) = filter((k,v) -> in(v["$K"], ids) , data)
    @eval export $F
end

filter_refs_by_image(d::RefExpData, ids) = map(i->d.img2ref[i], ids)
export filter_refs_by_image

# get methods
get_category_ids(d::RefExpData) = keys(d.categories)
export get_category_ids

function get_ref_ids(
    d::RefExpData; image_ids=[], cat_ids=[], ref_ids=[], split="")
    refs = d.refs
    for (_array,_filter) in product(_arrays, vcat(_filters..., :image))
        F = Symbol(:filter_, :ref_by_, _filter); A = Symbol(_arrays, :_ids)
        @eval refs = $F(refs, $A)
    end
    return refs
end
export get_ref_ids

function get_annotations_ids(
    d::RefExpData; image_ids=[], cat_ids=[], ref_ids=[])
    annotations = d.annotations
    for (_array,_filter) in product(_arrays, _filters)
        F = Symbol(:filter_, :annotations_by_, _filter)
        A = Symbol(_arrays, :_ids)
        @eval annotations = $F(annotations, $A)
    end
    return annotations
end
export get_annotations_ids

# utils
function _get_image_dir(datadir, dataset)::String
    subdir = ""
    if in(dataset, ("refcoco", "refcoco+", "refcocog"))
        subdir = "images/mscoco/images/train2014"
    elseif dataset == "refclef"
        subdir = "images/saiapr_tc-12"
    else
        error("There's no such dataset called as $dataset.")
    end
    return abspath(joinpath(datadir, subdir))
end

function _load_refs(datadir, dataset, datasplit)
    refsfile = abspath(joinpath(datadir, dataset, "refs("*datasplit*").p"))
    refs = open(refsfile, "r") do f
        pickle.loads(pybytes(read(f)))
    end
    return refs
end

function _get_instances(datadir, dataset)
    jsonfile = abspath(joinpath(datadir, dataset, "instances.json"))
    return JSON.parsefile(jsonfile)
end

end # module
