module ReferringExpressions

using PyCall, JSON
@pyimport cPickle as pickle

struct RefExpData
    # inputs
    datadir
    dataset
    datasplit
    data

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

        return new(datadir,dataset,datasplit,data,imgdir,refs,annotations,
                   images,categories,sentences,img2ref,img2ann,ref2ann,
                   ann2ref,cat2ref,sent2ref,sent2tok)
    end
end

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

export RefExpData

end # module
