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
    filter_refs_by_split(d.refs, split)
end
function filter_refs_by_split(refs, split="")
    isempty(split) && return refs
    if in(split, ("testA","testB","testC"))
        refs = filter((k,v) -> in(string(split[end]), v["split"]), refs)
    elseif in(split, ("testAB","testBC","testAC"))
        refs = filter((k,v) -> v["split"] == split, refs)
    elseif in(split, ("train","valid","test"))
        refs = filter((k,v) -> startswith(v["split"], split), refs)
    end
    return refs
end
export filter_refs_by_split

_filters = (
    (:categories, "category_id"), (:refs, "ref_id"), (:images, "image_id"))
_arrays = (:ref, :image, :annotation)
for ((_filter,_id), _array) in product(_filters, _arrays)
    F = Symbol(:filter_, _array, :s_by_, _filter)
    @eval $F(d::RefExpData, ids) = filter(
        (k,v) -> in(v[$_id], ids) , d.$_filter)
    @eval $F(data, ids) = filter((k,v) -> in(v[$_id], ids) , data)
    @eval export $F
end

# get methods
get_category_ids(d::RefExpData) = keys(d.categories)
export get_category_ids

function get_ref_ids(
    d::RefExpData; ref_ids=[], cat_ids=[], image_ids=[], split="")
    refs = d.refs
    refs = filter_refs_by_refs(refs, ref_ids)
    refs = filter_refs_by_categories(refs, cat_ids)
    refs = filter_refs_by_images(refs, image_ids)
    refs = filter_refs_by_split(refs, split)
end
export get_ref_ids

function get_annotations_ids(
    d::RefExpData; ref_ids=[], cat_ids=[], image_ids=[])
    data = d.annotations
    data = filter_annotations_by_refs(data, ref_ids)
    data = filter_annotations_by_categories(data, cat_ids)
    data = filter_annotations_by_images(data, image_ids)
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
